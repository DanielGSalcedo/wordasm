.MODEL SMALL
.STACK 100h

.DATA
titulo    DB '<< WORDASM >>$', 0Dh, 0Ah, '$'
cursorX   DB 1
cursorY   DB 3
menu_texto DB 0Dh, 0Ah, 'WORDASM - MENU PRINCIPAL', 0Dh, 0Ah
           DB '1. Nuevo archivo', 0Dh, 0Ah
           DB '2. Abrir archivo existente', 0Dh, 0Ah
           DB 'Seleccione una opcion: $'

nombre_archivo DB 100 DUP(0)   ; Guarda la ruta que el usuario escriba
mensaje_pedir_archivo DB 0Dh, 0Ah, 'Ingrese nombre del archivo: $'
nombre_archivo_input DB 100
                     DB ?
                     DB 100 DUP(0)
handle    DW ?
buffer    DB 80*20 DUP(' ')  ; 20 líneas de 80 columnas

.CODE

MAIN PROC NEAR
    MOV AX, @DATA
    MOV DS, AX

    
    CALL LimpiarPantalla
    CALL MenuPrincipal
    CALL LimpiarPantalla
    CALL DibujarMarco
    CALL MostrarTitulo
    CALL MostrarBuffer
    CALL EditorTexto

    MOV AH, 4Ch
    INT 21h
MAIN ENDP

; === Limpiar pantalla ===
LimpiarPantalla PROC NEAR
    MOV AH, 0
    MOV AL, 3
    INT 10h
    RET
LimpiarPantalla ENDP

; === Dibujar marco completo ===
DibujarMarco PROC NEAR
    ; Línea superior
    MOV DH, 2
    MOV DL, 0
draw_top:
    CALL PrintCharAt
    INC DL
    CMP DL, 79
    JLE draw_top

    ; Línea inferior
    MOV DH, 23
    MOV DL, 0
draw_bottom:
    CALL PrintCharAt
    INC DL
    CMP DL, 79
    JLE draw_bottom

    ; Bordes izquierdo y derecho
    MOV DH, 3
draw_sides:
    MOV DL, 0
    CALL PrintCharAt
    MOV DL, 79
    CALL PrintCharAt
    INC DH
    CMP DH, 22
    JLE draw_sides

    RET
DibujarMarco ENDP

; === Mostrar título ===
MostrarTitulo PROC NEAR
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 1
    MOV DL, 30
    INT 10h

    MOV AH, 09h
    LEA DX, titulo
    INT 21h
    RET
MostrarTitulo ENDP

; === Dibujar carácter del marco ===
PrintCharAt PROC NEAR
    MOV AH, 02h
    MOV BH, 0
    INT 10h

    MOV AH, 09h
    CMP DL, 0
    JE es_borde
    CMP DL, 79
    JE es_borde
    MOV AL, '-'     ; Horizontal
    JMP imprimir
es_borde:
    MOV AL, '|'     ; Vertical
imprimir:
    MOV BL, 0Fh
    MOV CX, 1
    INT 10h
    RET
PrintCharAt ENDP

; === Mostrar buffer en pantalla ===
MostrarBuffer PROC NEAR
    MOV SI, 0
    MOV DH, 3
mostrar_linea:
    MOV DL, 1
    MOV CX, 78
mostrar_col:
    MOV AH, 02h
    MOV BH, 0
    INT 10h
    MOV AL, buffer[SI]
    MOV AH, 0Eh
    INT 10h
    INC SI
    INC DL
    LOOP mostrar_col
    INC DH
    CMP DH, 22
    JLE mostrar_linea
    RET
MostrarBuffer ENDP

; === Menú principal ===
MenuPrincipal PROC NEAR
    MOV AH, 0
    MOV AL, 3
    INT 10h

    MOV AH, 09h
    LEA DX, menu_texto
    INT 21h


leer_opcion:
    MOV AH, 01h
    INT 21h
    CMP AL, '1'
    JE opcion_nuevo
    CMP AL, '2'
    JE opcion_abrir
    JMP leer_opcion

opcion_nuevo:
    MOV CX, 1600
    LEA DI, buffer
    MOV AL, ' '
    REP STOSB
    RET

opcion_abrir:
    CALL AbrirArchivo
    RET
MenuPrincipal ENDP


; === Editor principal ===
AbrirArchivo PROC
    ; Mostrar mensaje
    MOV AH, 09h
    LEA DX, mensaje_pedir_archivo
    INT 21h

    ; Leer cadena del usuario (INT 21h, función 0Ah)
    LEA DX, nombre_archivo_input
    MOV AH, 0Ah
    INT 21h

    ; Convertir a formato ASCIIZ para abrir
    ; nombre_archivo = dirección de texto a partir de offset +2
    LEA SI, nombre_archivo_input+2
    LEA DI, nombre_archivo
    MOV CX, 100
copiar_nombre:
    LODSB
    CMP AL, 13
    JE fin_copiar_nombre
    STOSB
    LOOP copiar_nombre
fin_copiar_nombre:
    MOV AL, 0
    STOSB

    ; Abrir archivo
    MOV AH, 3Dh
    MOV AL, 0
    LEA DX, nombre_archivo
    INT 21h
    JC error_open
    MOV handle, AX

    ; Leer contenido
    MOV AH, 3Fh
    MOV BX, handle
    LEA DX, buffer
    MOV CX, 1600
    INT 21h

    ; Cerrar
    MOV AH, 3Eh
    MOV BX, handle
    INT 21h
    RET

error_open:
    ; Podrías mostrar un mensaje de error aquí
    RET
AbrirArchivo ENDP


EditorTexto PROC NEAR

loop_input:
    CALL ActualizarCursor
    MOV AH, 0
    INT 16h
    CMP AL, 8
    JE hacer_retroceso
    CMP AL, 13
    JE hacer_nuevalinea
    CMP AL, 27
    JE salir_editor
    CMP AL, 0
    JE checar_extendido

    ; Escribir carácter
    CALL EscribirCaracter
    JMP loop_input

checar_extendido:       ; <-- Segunda lectura para tecla extendida
    ; Ahora AL tiene el código de la flecha
    CMP AH, 4Bh      ; Izquierda
    JE mover_izq
    CMP AH, 4Dh      ; Derecha
    JE mover_der
    CMP AH, 48h      ; Arriba
    JE mover_arr
    CMP Ah, 50h      ; Abajo
    JE mover_aba
    JMP loop_input

mover_izq:
    CALL MoverIzquierda
    JMP loop_input
mover_der:
    CALL MoverDerecha
    JMP loop_input
mover_arr:
    CALL MoverArriba
    JMP loop_input
mover_aba:
    CALL MoverAbajo
    JMP loop_input

hacer_retroceso:
    CALL Retroceso
    JMP loop_input

hacer_nuevalinea:
    CALL NuevaLinea
    JMP loop_input

salir_editor:
    RET
EditorTexto ENDP
; === Escribir un carácter ===
EscribirCaracter PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; Guardar el carácter en DL
    MOV DL, AL

    ; Calcular índice del buffer = (cursorY - 3) * 80 + (cursorX - 1)
    MOV AL, cursorY
    SUB AL, 3
    CBW
    MOV BL, 80
    MUL BL         ; AX = fila * 80
    MOV BX, AX
    MOV AL, cursorX
    DEC AL
    CBW
    ADD BX, AX     ; BX = posición final
    MOV SI, BX     ; SI = índice de inserción

    ; Desplazar hacia la derecha hasta el final del buffer (simple hasta 79 col)
    MOV CX, 78
    ADD SI, CX     ; SI al final de la línea
desplazar:
    CMP SI, BX
    JL fin_desplazar
    MOV AL, buffer[SI]
    MOV buffer[SI+1], AL
    DEC SI
    JMP desplazar
fin_desplazar:

    ; Insertar el nuevo carácter en BX (posición original)
    MOV AL, DL
    MOV buffer[BX], AL

    ; Mostrar carácter en pantalla
    MOV AH, 02h
    MOV BH, 0
    MOV DH, cursorY
    MOV DL, cursorX
    INT 10h

    MOV AH, 0Eh
    MOV AL, buffer[BX]
    INT 10h

    ; Avanzar cursor
    INC cursorX
    CMP cursorX, 78
    JBE fin_insertar
    CALL NuevaLinea
fin_insertar:

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
EscribirCaracter ENDP


Retroceso PROC NEAR
    CMP cursorX, 1
    JBE retroceso_linea_anterior

    DEC cursorX
    JMP borrar_caracter

retroceso_linea_anterior:
    CMP cursorY, 3
    JBE salir_retroceso      ; Ya está en la primera línea, no hace nada
    DEC cursorY
    MOV cursorX, 78          ; Última columna

borrar_caracter:
    ; Calcular índice en buffer: (cursorY-3)*80 + (cursorX-1)
    MOV BL, cursorY
    SUB BL, 3
    MOV BH, 0
    MOV AX, BX
    MOV BX, 80
    MUL BX
    MOV BX, AX
    MOV AL, cursorX
    DEC AL
    ADD BX, AX
    MOV SI, BX

    MOV buffer[SI], ' '

    ; Borrar en pantalla
    MOV AH, 02h
    MOV BH, 0
    MOV DH, cursorY
    MOV DL, cursorX
    INT 10h

    MOV AH, 0Eh
    MOV AL, ' '
    INT 10h

salir_retroceso:
    RET
Retroceso ENDP

; === Nueva línea ===
NuevaLinea PROC NEAR
    CMP cursorY, 22
    JAE salir_nl
    INC cursorY
    MOV cursorX, 1
salir_nl:
    RET
NuevaLinea ENDP

; === Mover cursor ===
MoverIzquierda PROC NEAR
    CMP cursorX, 1
    JBE fin_mover_izq
    DEC cursorX
fin_mover_izq:
    CALL ActualizarCursor
    RET
MoverIzquierda ENDP

MoverDerecha PROC NEAR
    CMP cursorX, 78
    JAE fin_mover_der
    INC cursorX
fin_mover_der:
    CALL ActualizarCursor
    RET
MoverDerecha ENDP

MoverArriba PROC NEAR
    CMP cursorY, 3
    JBE fin_mover_arr
    DEC cursorY
fin_mover_arr:
    CALL ActualizarCursor
    RET
MoverArriba ENDP

MoverAbajo PROC NEAR
    CMP cursorY, 22
    JAE fin_mover_aba
    INC cursorY
fin_mover_aba:
    CALL ActualizarCursor
    RET
MoverAbajo ENDP

; === Actualizar posición del cursor en pantalla ===
ActualizarCursor PROC NEAR
    MOV AH, 02h
    MOV BH, 0
    MOV DH, cursorY
    MOV DL, cursorX
    INT 10h
    RET
ActualizarCursor ENDP

END MAIN