# Makefile Assembler
ASM := nasm
ASMFLAGS := -f elf64
LD := ld
LDFLAGS := -s
TARGET := asm
SRC := assembler.asm
OBJ := assembler.o

.PHONY: all clean test run exemplo bench stress

all: $(TARGET)

$(TARGET): $(OBJ)
	@$(LD) $(LDFLAGS) -o $@ $<

$(OBJ): $(SRC)
	@$(ASM) $(ASMFLAGS) $< -o $@

clean:
	@rm -f $(OBJ) $(TARGET) test.* exemplo.* bench.* stress.*

test: $(TARGET)
	@printf "nop \nmov \nadd \nret " > test.s
	@/usr/bin/time -f "%E" ./$(TARGET) test.s test.bin 2>&1 || ./$(TARGET) test.s test.bin
	@hexdump -C test.bin 2>/dev/null || xxd test.bin
	@ls -lh test.bin $(TARGET)

run: test

exemplo: $(TARGET)
	@printf "mov \n72 \nadd \n29 \nret " > exemplo.s
	@./$(TARGET) exemplo.s exemplo.bin
	@hexdump -C exemplo.bin 2>/dev/null || xxd exemplo.bin
	@printf "Esperado: B8 48 05 1D C3\n"

bench: $(TARGET)
	@i=0; while [ $i -lt 25 ]; do \
		printf "nop \nmov \nadd \nret " >> bench.s; \
		i=$((i+1)); \
	done
	@wc -l bench.s
	@/usr/bin/time -v ./$(TARGET) bench.s bench.bin 2>&1 | grep -E "Elapsed|Maximum|User|System" || \
	 /usr/bin/time -f "%E (%U usr %S sys)" ./$(TARGET) bench.s bench.bin 2>&1 || \
	 time ./$(TARGET) bench.s bench.bin
	@printf "Entrada: %s bytes | Saída: %s bytes\n" "$(wc -c < bench.s)" "$(wc -c < bench.bin)"

stress: $(TARGET)
	@i=0; while [ $i -lt 250 ]; do \
		printf "push\npop \nxor \nret " >> stress.s; \
		i=$((i+1)); \
	done
	@printf "%s linhas\n" "$(wc -l < stress.s)"
	@/usr/bin/time -f "%E" ./$(TARGET) stress.s stress.bin 2>&1 || time ./$(TARGET) stress.s stress.bin
	@printf "%s bytes gerados\n" "$(wc -c < stress.bin)"
