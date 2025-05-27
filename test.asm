.MODEL small
.STACK 100h

.DATA
    TextBuffer    DB 1600 DUP(' ')
    PathBuffer    DB 80, 0
    SaveBuffer    DB 80, 0

    MenuText      DB 0Dh,0Ah, "MENU PRINCIPAL",0Dh,0Ah
                  DB "1. Nuevo archivo",0Dh,0Ah
                  DB "2. Abrir archivo existente",0Dh,0Ah
                  DB "Seleccione opcion: $"
    OpenPrompt    DB 0Dh,0Ah, "Ruta del archivo a abrir (C:\\TEXTO.TXT): $"
    SavePrompt    DB 0Dh,0Ah, "Nombre de archivo para guardar: $"
    NoFileMsg     DB 0Dh,0Ah, "Archivo no encontrado.$"
    CRLFBytes     DB 13,10

.CODE
main PROC
    mov ax, @DATA
    mov ds, ax

MostrarMenu:
    ; Limpiar pantalla
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0
    mov dx, 184Fh
    int 10h

    ; Título
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 33
    int 10h
    mov ah, 0Eh
    mov al, '<'     ; Imprimir << WORDASM >>
    int 10h
    int 10h
    mov al, ' '
    int 10h
    mov al, 'W'
    int 10h
    mov al, 'O'
    int 10h
    mov al, 'R'
    int 10h
    mov al, 'D'
    int 10h
    mov al, 'A'
    int 10h
    mov al, 'S'
    int 10h
    mov al, 'M'
    int 10h
    mov al, ' '
    int 10h
    mov al, '>'
    int 10h
    int 10h

    ; Nueva línea
    mov ah, 02h
    mov dl, 0Dh
    int 21h
    mov dl, 0Ah
    int 21h

    ; Mostrar menú
    mov ah, 09h
    mov dx, OFFSET MenuText
    int 21h

    ; Leer opción
    mov ah, 01h
    int 21h
    cmp al, '1'
    je NuevoArchivo
    cmp al, '2'
    je AbrirArchivo
    jmp MostrarMenu

NuevoArchivo:
    lea di, TextBuffer
    mov cx, 1600
    mov al, ' '
    rep stosb
    jmp DibujarMarco

AbrirArchivo:
    mov ah, 09h
    mov dx, OFFSET OpenPrompt
    int 21h
    lea dx, PathBuffer
    int 21h

    lea dx, PathBuffer+2
    mov ah, 3Dh
    mov al, 0
    int 21h
    jc ArchivoNoEncontrado
    mov bx, ax

    mov ah, 3Fh
    mov cx, 1600
    lea dx, TextBuffer
    int 21h

    mov ah, 3Eh
    int 21h
    jmp DibujarMarco

ArchivoNoEncontrado:
    mov ah, 09h
    mov dx, OFFSET NoFileMsg
    int 21h
    jmp MostrarMenu

DibujarMarco:
    ; Código de dibujo aquí
    ; (Lo puedes añadir tú si ya lo tienes funcional)

    ; Simulación de ir al bucle del editor
    jmp EditLoopStart

EditLoopStart:
    ; Código del editor, movimiento y escritura aquí...
    ; Divide los saltos largos en dos usando intermediarios si es necesario.
    ; Este es solo el punto de entrada para continuar.
    ; Puedes reusar tus funciones ya corregidas.

    ; Fin simulado
    mov ah, 4Ch
    int 21h

main ENDP
END main
