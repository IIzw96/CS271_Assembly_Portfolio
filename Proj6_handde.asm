TITLE String Primitives and Macros    (Proj6_handde.asm)

; Author:				Derek Hand
; Last Modified:		03/11/2021
; OSU email address:	handde@oregonstate.edu
; Course number/section:   CS271 Section 401
; Project Number:  6              Due Date: 03/14/2021
; Description:		Practice implementing my own readval and writeval procedures. Takes user input and checks if they 
;					entered valid data (SDWORD) and converts it to a numerical representation. It then calculates the
;					sum of the entered values, and the average of the values


INCLUDE Irvine32.inc

LOWVALUE	=	2147483648		; because negatives are weird
REPEATSUM	=	1

; ---------------------------------
; Name:	mDisplayString
;
; Displays string to the command line
;
; Preconditions:	string is a string
;
; Receives:		string	=	the address of string

mDisplayString	MACRO	string:REQ
	push	EDX		; preserve register
	mov		EDX, string
	call	WriteString
	pop		EDX		; restore register
ENDM

; ---------------------------------
; Name:	mGetString
;
; Description:	Display a prompt, then get the user's keyboard input and store into a memory
;				location. 
;
; Preconditions:	message is initialized as a string
;					array is a place holder for the readstring command
;					size tells readstring how many ascii characters to read in
;
; Receives:			message:	prompt to display
;					array:		a place to put the string
;					size:		the allowable number of characters to read, allows space for null termination
;
; Returns:			The string stored in the array

mGetString	MACRO	message:REQ, array:REQ, size:REQ
	push	EDX
	push	ECX

	mov		EDX, message
	call	Writestring
	mov		EDX, array
	mov		ECX, size
	call	ReadString

	pop		ECX
	pop		EDX
ENDM

.data

intro			BYTE	"Designing low-level I/O procedures by Derek Hand", 13, 10, 0
instructions	BYTE	"Please provide 10 signed decimal integers. Each numner needs to be", 13, 10
				BYTE	"small enough to fit inside a 32 bit register. After you have finished", 13, 10
				BYTE	"inputting the raw numbers, I will display a list of the integers,", 13, 10
				BYTE	"their sum, and their average value.", 13, 10, 0

promptNumber	BYTE	"Please enter a signed number: ", 0
errorPrompt		BYTE	"ERROR: This is not a valid number. Try again.", 13, 10, 0
enteredPrompt	BYTE	"These are your numbers: ", 13, 10, 0
comma			BYTE	", ", 0
sumPrompt		BYTE	"The sum of these numbers is: ", 0
meanPrompt		BYTE	"The rounded average is: ", 0
farewell		BYTE	"Aufwiedersehen!", 13, 10, 0

array			SDWORD	10 DUP(?)
sum				SDWORD	10 DUP(?)
mean			SDWORD	10 DUP(?)

.code
main PROC

	push	OFFSET instructions 
	push	OFFSET intro
	call	INTRODUCTION				; greets user

	push	LOWVALUE
	push	OFFSET array
	push	LENGTHOF array
	push	OFFSET promptNumber
	push	OFFSET errorPrompt			; fills the array with the values entered by user
	call	fillArray

	push	OFFSET array
	push	LENGTHOF array
	push	OFFSET enteredPrompt		; writes out the numbers the user entered
	push	OFFSET comma
	call	writeVal

	push	sum
	push	OFFSET	array
	push	OFFSET	LENGTHOF array		; calculates the sum
	call	calculateSum
	pop		sum

	push	OFFSET	sum					; writes the sum
	push	REPEATSUM
	push	OFFSET	sumPrompt
	push	OFFSET	comma
	call	writeVal

	push	mean
	push	sum
	push	LENGTHOF array				; calculate mean
	call	calculateMean
	pop		mean

	push	OFFSET	mean
	push	OFFSET	REPEATSUM
	push	OFFSET	meanPrompt			; display mean
	push	OFFSET	comma
	call	WriteVal

	push	OFFSET	farewell
	call	goodbye						; adios

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------
; Name: INTRODUCTION
; 
; Displays program description, program title, and the programers name, and any extra credit attempted
;
; Preconditions:	intro:			is a string
;					instructions:	is a string
;
; Receives:
;		[EBP + 8]	=	intro
;		[EBP + 12]	=	instructions

INTRODUCTION PROC
	push	EBP			; preserve registers
	mov		EBP, ESP	

	mDisplayString	[EBP + 8]	; intro string
	call	CrLf
	mDisplayString	[EBP + 12]	; instructions
	call	CrLf

	pop		EBP					; restore registers
	ret		8
INTRODUCTION ENDP

; ---------------------------------
; Name: fillArray
; 
; Description:	Gets the users data in order to fill the array. It will call the readVal procedure
; 
; Preconditions:	errorPrompt is a string
;					promptNumber is a string
;					LENGTHOF array is the size of the array to be filled
;					array is the initialized
;				
; Postconditions:	array is filled with valid values
; 
; Receives:			[EBP + 8]	=	errorPrompt		Informs the user that they entered an invalid number
;					[EBP + 12]	=	promptNumber	prompts the user for input
;					[EBP + 16]	=	LENGTHOF array	used for counter
;					[EBP + 20]	=	array			the array for us to fill
;					[EBP + 24]	=   LOWVALUE		low value for SDWORD

fillArray PROC
	push	EBP				; preserve registers
	mov		EBP, ESP
	push	ECX				; set up counter and array
	mov		ECX, [EBP + 16]
	mov		ESI, [EBP + 20]
	;push	ESI				; preserve esi, other procedures use it

	_fillTop:
		push	[EBP + 24]	; low limit
		push	[EBP + 12]	; push promptNumber and errorPrompt to stack. Will use in readVal
		push	[EBP + 8]	; errorprompt
		call	readVal
		pop		[ESI]
		add		ESI, 4

	LOOP _fillTop

	pop		ECX
	pop		EBP				; restore registers
	ret		20
fillArray ENDP

; ---------------------------------
; Name:	CalculateSum
;
; Description:		Calculates the sum and populates the sum variable
;
; Preconditions:	array is converted to numerical values
;					sum is initialized as an SDWORD
;
; Postconditions:	sum will hold the sum of the entered numbers
;
; Receives:			[EBP + 8]	=	arraySize
;					[EBP + 12]	=	array
;					[EBP + 16]	=	sum
;
; Returns:			[EBP + 16]

calculateSum	PROC
	push	EBP			; preserve registers
	mov		EBP, ESP
	push	ESI
	push	ECX
	push	EAX

	mov		ESI, [EBP + 12]
	mov		ECX, [EBP + 8]		; set up array and counter
	mov		EAX, 0
	mov		[EBP + 16], EAX

	_sumTop:
		mov		EAX, [EBP + 16]
		add		EAX, [ESI]
		mov		[EBP + 16], EAX
		add		ESI, 4
	LOOP _sumTop
		
	pop		EAX
	pop		ECX
	pop		ESI
	pop		EBP			; restore registers
	ret		8			; will pop sum value into variable in main
calculateSum	ENDP

; ---------------------------------
; Name:	readVal
; 
; Description:		Reads the users input values
; 
; Preconditions:	errorPrompt and promptNumber are strings
;					lowvalue just being passed until we reach ascii conversion
;				
; Postconditions:	[EBP + 16] will hold the converted number
; 
; Receives:			[EBP + 8]	errorPrompt message
;					[EBP + 12]	promptNumber message
;					[EBP + 16]	LOWVALUE 
;
; Returns:			a valid number in [EBP + 16] 

readVal PROC
	LOCAL	tempArr[15]:BYTE, valid:DWORD

	push		ESI
	push		ECX					; preserve registers

	mov			EAX, [EBP + 12]		
	lea			EBX, tempArr

	_readvalTop:
		mGetString	EAX, EBX, LENGTHOF tempArr
	
		push	[EBP + 16]			; low value
		push	[EBP + 8]			; error prompt
		lea		EAX, valid			; set up for data validation by sending it the entered string etc
		push	EAX
		lea		EAX, tempArr
		push	EAX
		push	LENGTHOF tempArr
		call	dataValidation
		pop		EDX
		mov		[EBP + 16], EDX
		mov		EAX, valid
		cmp		EAX, 1
		JNE		_getNewData
		jmp		_readValBottom

	_getNewData:
	mov		EAX, [EBP + 12]
	lea		EBX, tempArr
	jmp		_readvalTop

	_readValBottom:

	pop		ECX
	pop		ESI				; restore registers
	ret		8
readVal ENDP

; ---------------------------------
; Name: calculateMean
; 
; Description:		Calculates the raounded mean (rounds down)
;
; Preconditions:	Sum has been calculated
;					mean has been initialized as an SDWORD array
;
; Receives:			[EBP + 8]	=	arraySize
;					[EBP + 12]	=	sum
;					[EBP + 16]	=	mean
;
; Returns:			[EBP + 16]	=	sum

calculateMean	PROC
	push	EBP		; preserve registers
	mov		EBP, ESP
	xor		EAX, EAX	; clear eax
	xor		EDX, EDX	; clear edx

	mov		EAX, [EBP + 12]
	mov		EBX, [EBP + 8]

	CDQ
	IDIV	EBX

	mov		[EBP + 16], EAX

	pop		EBP
	ret		8
calculateMean	ENDP

; ---------------------------------
; Name: writeVal
;
; Description:		Converts a numeric SDWORD value to a string of ascii digits. It then invokes the
;					mDisplayString macro to print the ascii representation of the SDWORD.
; 
; Preconditions:	array has been filled with valid numbers
;					arraySize is the size of the array
;					enteredPrompt is a string
;					comma is a string
; 
; Receives:			[EBP + 20]	=	array
;					[EBP + 16]	=	arraySize
;					[EBP + 12]	=	enteredPrompt
;					[EBP + 8]	=	comma


writeVal PROC
	push	EBP			; preserve registers
	mov		EBP, ESP
	push	ESI
	push	ECX
	push	EBX

	call	CrlF
	mDisplayString	[EBP + 12]

	mov		ESI, [EBP + 20]
	mov		ECX, [EBP + 16]	; set up array and loop counter
	mov		EBX, 1
	_writeValLoop:
		push	[ESI]			; send the first value to stack
		call	writeAscii
		add		ESI, 4
		cmp		EBX, [EBP + 16]	; have we reached the end of the array
		JAE		_doneWriteVal	; don't write comma after last value
		mDisplayString	[EBP + 8]
		inc		EBX
	LOOP _writeValLoop

	_doneWriteVal:
		call	CrLf
		pop		EBX
		pop		ECX
		pop		ESI
		pop		EBP			; restore registers
		ret		16
writeVal ENDP

; ---------------------------------
; Name:	writeAscii
; 
; Description:		writes the ascii character
;
; Preconditions:	Array has the numerical values of what the user entered
;
; Receives:			[EBP + 8]	=	numerical value in array

writeAscii	PROC
	LOCAL	string[15]:BYTE
	LEA		EAX, string

	push	EAX
	push	[EBP + 8]
	call	convertChar
	lea		eax, string
	mDisplayString	EAX

	ret 4
writeAscii	ENDP


; ---------------------------------
; Name:	convertChar
;
; Description:	Converts the number to write
;
; Preconditions:	stringarray is the local variable in writeAscii
;					numerical value has already been converted 
; 
; Postconditions:	[EBP + 12] now has the ascii representation of the numerical value
;
; Receives:			[EBP + 8]	=	numerical value
;					[EBP + 12]	=	string array
;
; Returns:			[EBP + 12] (EDI)	=	converted value

convertChar	PROC
	LOCAL	temp:DWORD
	mov		EAX, [EBP + 8]
	cmp		EAX, 0
	push	EBX
	mov		EBX, 10	
	push	ECX
	mov		ECX, 0	; used for loop
	CLD
	JL		_negativeConvert
	jmp		_divideTen

	_negativeConvert:
		IMUL	EAX, -1
		_divideTenNegative:
		mov		EDX, 0	
		DIV		EBX
		push	EDX
		INC		ECX
		CMP		EAX, 0
		JNE		_divideTenNegative
	mov		EDI, [EBP + 12]
	mov		al,	BYTE PTR 45
	STOSB
	jmp		_pushChar


	_divideTen:			; divide, then push characters in reverse
		mov		EDX, 0	
		DIV		EBX
		push	EDX
		INC		ECX
		CMP		EAX, 0
		JNE		_divideTen

	MOV		EDI, [EBP + 12]		; get ready to store character 

	_pushChar:
		pop		temp				; put edx in temp
		mov		al, BYTE PTR temp	; force temp into al, movzx doesn't seem to work well in reverse
		add		al, 48				; value is now in ascii, put 
		STOSB						; put ascii in EDI
	LOOP	_pushChar
	mov		AL, 0					; null terminate string
	stosb
	pop		ECX
	pop		EBX
	ret 8
convertChar	ENDP

; ---------------------------------
; Name: dataValidation
; Description:		Performs data validation on users input
; 
; Preconditions:	errorPrompt is a string
;					valid is initialized as a local variable in readVal and used as a flag for valid numbers
;					tempArr holds the string that was entered
;					lowvalue is just being passed until we get to the ascii conversion
;					arraySize is initialize to size of array
;				
; Postconditions:	[EBP + 16] will change either to 1 (valid) or 666 (invalid
;					[EBP + 24] will host the valid number, when there is one
; 
; Receives:			[EBP + 8]	= arraySize
;					[EBP + 12]	= tempArr
;					[EBP + 16]	= Valid
;					[EBP + 20]	= errorPrompt
;					[EBP + 24]	= LOWVALUE
; 
; Returns:			[EBP + 24]	a valid number that was converted from a string
;					[EBP + 16]	1 (valid)
;					[EBP + 16]	666 (invalid)

dataValidation PROC
	LOCAL	invalid:SDWORD
	
	mov		ESI, [EBP + 12]		; load the string array
	mov		ECX, [EBP + 8]		; set up loop counter
	cld

	LODSB						; checks first value in array for sign, if no sign, assume positive
								; will check if the number is in a valid range in the loop
	cmp		AL, 45
	JE		_negative
	cmp		AL, 43
	JE		_positive
	JMP		_positiveTop	; no sign, number is presumably positive

	_positive:
		LODSB				;load next value in, don't need to worry about sign, will jump straight
							; here if there is no sign
		_positiveTop:
			CMP		AL, 0			; verify all characters are valid, signs were checked, just checking for numbers
			JE		_endOfString
			CMP		AL, 57
			JA		_invalidEntry
			CMP		AL, 48
			JB		_invalidEntry
			sub		ECX, 1
			LODSB
			JMP		_positiveTop

	_negative:
		LODSB
		_negativeTop:
			CMP		AL, 0
			JE		_endOfString
			CMP		AL, 57
			JA		_invalidEntry
			CMP		AL, 48
			JB		_invalidEntry
			sub		ECX, 1
			LODSB
			JMP		_negativeTop

	_endOfString:
		mov		EDX, [EBP + 8]		; hopefully something was entered, if not, invalid
		cmp		ECX, EDX
		JE		_invalidEntry		; nothing entered, tell user they need to try again
		LEA		EAX, invalid
		mov		EDX, 0
		mov		[EAX], EDX
		push	[EBP + 24]			; LOWVALUE
		push	[EBP + 12]
		push	[EBP + 8]
		LEA		EDX, invalid
		push	EDX
		call	asciiToNumber
		mov		EDX, invalid
		cmp		EDX, 666
		JE		_invalidEntry
		mov		EDX, [EBP + 16]
		mov		EAX, 1				; valid is now set to true
		mov		[EDX], EAX	
		jmp		_endValidation

	_invalidEntry:
		mDisplayString [EBP + 20]
		call	CrLf
		mov		EDX, [EBP + 16]		; valid flag will be changed to 666, the number of the beast
		mov		EAX, 666
		mov		[EDX], EAX
		jmp		_endValidation2

	_endValidation:
		pop		EDX					; populate edx with the converted number
		mov		[EBP + 24], EDX
		ret		16					; send converted number back to readval
		jmp		_doneValidation
	_endValidation2:
		pop		EDX
		mov		EDX, [EBP + 24]
		ret		16

	_doneValidation:
dataValidation ENDP

; ---------------------------------
; Name: asciiToNumber
; Description:		Converts ascii to number
; 
; Preconditions:	invalid local variable address from validation proc
;					arraysize is intialized to the size of the array
;					users input number has the string representation of what they typed
;					LOWVALUE is a constant intialized to positive value for the negative low limit
;				
; Postconditions:	[EBP + 20] changes
;					[EBP + 8]  changes
; 
; Receives:			[EBP + 8]	=	invalid local variable address
;					[EBP + 12]	=	arraySize for loop counter
;					[EBP + 16]	=	User's input number
;					[EBP + 20]	=	LOWVALUE
; 
; Returns:			[EBP + 20]		converted value if applicable, 0 otherwise
;					[EBP + 8]		666 if invalid

asciiToNumber PROC
	LOCAL saveNumber:DWORD		; used for the conversion into a number

	mov		ECX, [EBP + 12]		; arraySize counter
	mov		ESI, [EBP + 16]		; user's input
	LEA		EAX, saveNumber
	mov		saveNumber, 0
	XOR		EAX, EAX			; clear flags and set register to 0
	
	_loadValue:
		LODSB
		CMP		AL, 45
		JE		_negativeValue
		CMP		AL, 43
		JE		_positiveValue
		jmp		_topPosValue
		
		_negativeValue:
			LODSB
			CMP		AL, 0
			JE		_negativeDone
			movzx	EBX, AL
			sub		EBX, 48
			mov		EDI, 10
			mov		EAX, saveNumber
			mul		EDI
			add		EAX, EBX		; convert number to digit
			mov		saveNumber, EAX	; save the converted value
			mov		EDI, [EBP + 20]
			cmp		saveNumber, EDI
			JA		_tooBig

		LOOP _negativeValue

		_negativeDone:
			mov		EAX, saveNumber
			mov		EBX, [EBP + 20]
			CMP		EAX, EBX
			JA		_tooBig
			mov		EDI, -1
			IMUL	EAX, EDI
			mov		saveNumber, EAX
			jmp		_done

		_positiveValue:
			LODSB
			_topPosValue:
				CMP		AL, 0
				JE		_done
				movzx	EBX, AL
				sub		EBX, 48
				mov		EDI, 10
				mov		EAX, saveNumber
				mul		EDI
				JO		_tooBig
				add		EAX, EBX		; convert number to digit
				JO		_tooBig
				mov		saveNumber, EAX	; save the converted value
				LODSB
			LOOP _topPosValue
	
	_tooBig:
		mov		EBX, [EBP + 8]
		mov		EAX, 666				; the number of the beast
		mov		[EBX], EAX
		mov		EAX, 0
		mov		[EBP + 20], EAX
		jmp		_done2

	_done:
		mov		EAX, saveNumber
		mov		[EBP + 20], EAX		; converted number in stack instead of ascii characters, 
									; 0 as place holder if number was not converted
	_done2:
		ret 12		; preserve the converted number, place it in array
asciiToNumber ENDP

; ---------------------------------
; Name:	goodbye
; 
; Description:	Tells user goodby
;
; receives:		[EBP + 8]	=	goodbye prompt
;
; preconditions:	goodbye prompt is a string

goodbye		PROC
	push	EBP
	mov		EBP, ESP

	mDisplayString	[EBP + 8]

	pop		EBP
	ret		4
goodbye		ENDP

END main