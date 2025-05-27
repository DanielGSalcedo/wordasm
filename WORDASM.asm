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

 prompt     db 0Dh, 0Ah, 'Ingrese la ruta del archivo: $'
    errOpen    db 0Dh, 0Ah, "Error: no se pudo abrir el archivo.$"
    errRead    db 0Dh, 0Ah,"Error al leer el archivo.$"
    ; Búfer para la función 0Ah (lectura de nombre/ruta)
    filenameBuff db 128, 0, 128 dup(0)
    ; Búfer para el contenido del archivo
    fileBuffer   db 1600 dup(0) 

mensaje_guardar DB 0Dh, 0Ah, 'Ingrese el nombre del archivo para guardar: $'
nombre_archivo_input DB 100, 0, 100 DUP(0)
nombre_archivo DB 128 DUP(0)
handle    DW ?
buffer    DB 80*20 DUP(' ')  ; 20 líneas de 80 columnas


.CODE

MAIN PROC NEAR
    MOV AX, @DATA
    MOV DS, AX
    
    CALL LimpiarPantalla
    CALL MenuPrincipal
  
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
    ; Limpiar pantalla (modo texto)
    mov ah, 0
    mov al, 3
    int 10h

MenuLoop:
    ; Mostrar texto del menú
    mov ah, 09h
    lea dx, menu_texto
    int 21h

    ; Leer una tecla
    mov ah, 01h
    int 21h

    ; Comparar la opción ingresada
    cmp al, '1'
    je opcion_nuevo

    cmp al, '2'
    je opcion_abrir

    ; Si no es una opción válida, volver a mostrar el menú
    jmp MenuLoop

opcion_nuevo:
    call LimpiarPantalla
    call DibujarMarco
    call MostrarTitulo
    call EditorTexto

opcion_abrir:
    call AbrirArchivo
    call LimpiarPantalla
    call DibujarMarco
    call MostrarTitulo
    call MostrarBuffer
    call EditorTexto

MenuPrincipal ENDP

AbrirArchivo PROC

     ; Mostrar prompt
    mov ah, 9
    mov dx, OFFSET prompt
    int 21h

    ; Leer ruta con INT 21h AH=0Ah
    lea dx, filenameBuff
    mov ah, 0Ah
    int 21h

    ; Convertir entrada a ASCIIZ (reemplazar CR final con 0)
    mov cl, [filenameBuff+1]
    mov ch, 0
    lea si, filenameBuff
    add si, 2
    add si, cx
    mov byte ptr [si], 0


    ; Abrir archivo en modo lectura (INT 21h AH=3Dh, AL=0)
    lea dx, filenameBuff+2
    mov ah, 3Dh
    mov al, 0
    int 21h
    mov bx, ax         ; guardar manejador en BX

    ; Leer contenido del archivo (INT 21h AH=3Fh)
    mov ah, 3Fh
    mov cx, 1600
    lea dx, buffer
    int 21h
    mov cx, ax         ; CX = bytes leídos

    RET
AbrirArchivo ENDP

GuardarArchivo PROC NEAR
    call LimpiarPantalla
    ; Mostrar mensaje
    MOV AH, 09h
    LEA DX, mensaje_guardar
    INT 21h

    ; Leer nombre de archivo del usuario
    LEA DX, nombre_archivo_input
    MOV AH, 0Ah
    INT 21h

    ; Limpiar el buffer de destino
    LEA DI, nombre_archivo
    MOV CX, 128
    MOV AL, 0
    REP STOSB

    ; Obtener longitud real ingresada
    XOR CH, CH
    MOV CL, [nombre_archivo_input + 1]
    CMP CX, 0
    JE error_guardar_nombre_vacio

    ; Copiar nombre ingresado
    LEA SI, [nombre_archivo_input + 2]
    LEA DI, nombre_archivo
    MOV BX, CX          ; Guardar longitud
copiar_nombre:
    MOV AL, [SI]
    CMP AL, 13          ; ENTER
    JE fin_copiar
    MOV [DI], AL
    INC SI
    INC DI
    LOOP copiar_nombre

fin_copiar:
    ; Agregar extensión .TXT si no hay punto
    LEA SI, nombre_archivo
    MOV CX, BX          ; Recuperar longitud original
buscar_punto:
    MOV AL, [SI]
    CMP AL, '.'
    JE continuar_guardado  ; Ya tiene extensión
    CMP AL, 0
    JE poner_extension     ; Llegamos al final sin punto
    INC SI
    LOOP buscar_punto

poner_extension:
    MOV BYTE PTR [SI], '.'
    MOV BYTE PTR [SI+1], 'T'
    MOV BYTE PTR [SI+2], 'X'
    MOV BYTE PTR [SI+3], 'T'
    MOV BYTE PTR [SI+4], 0

continuar_guardado:
    ; Crear archivo
    MOV AH, 3Ch         ; Función crear archivo
    XOR CX, CX          ; Atributos normales
    LEA DX, nombre_archivo
    INT 21h
    JC error_guardar
    MOV handle, AX      ; Guardar handle

    ; Escribir contenido
    MOV AH, 40h         ; Función escribir archivo
    MOV BX, handle      ; Handle del archivo
    LEA DX, buffer      ; Buffer de datos
    MOV CX, 1600        ; Cantidad de bytes a escribir
    INT 21h

    ; Cerrar archivo
    MOV AH, 3Eh         ; Función cerrar archivo
    MOV BX, handle
    INT 21h
    RET

error_guardar_nombre_vacio:
    RET

error_guardar:
    RET
GuardarArchivo ENDP

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
    CALL GuardarArchivo
    MOV AH, 4Ch
    INT 21h
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