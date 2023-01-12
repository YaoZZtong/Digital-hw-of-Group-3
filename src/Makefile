ROM := main.gb
OBJ := main.o

$(ROM): $(OBJ)
	rgblink -o $@ $<
	rgbfix -v -p 0xFF $@
	rgblink -n $*.sym $(OBJ)

$(OBJ): main.asm
	rgbasm -L -o $@ $<

clean:
	rm -f $(OBJ) $(ROM)
