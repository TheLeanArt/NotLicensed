RGBLINK = rgblink
RGBFIX  = rgbfix
RGBASM  = rgbasm
RGBGFX  = rgbgfx

TITLE = NOTLICENSED
TARGET = demo.gb
SYM = demo.sym

RGBLINKFLAGS = -n $(SYM)
RGBFIXFLAGS  = -v -p 0xFF -t $(TITLE)
RGBASMFLAGS  = -I inc -I art

OBJS = \
	src/intro.o \
	src/intro_drop.o \
	src/intro_lut.o \
	src/oamdma.o \
	
INC = \
	inc\hardware.inc \
	inc\common.inc \
	inc\intro.inc \

INTRO_1BPP = \
	art/intro_not.1bpp \
	art/intro_top.1bpp \
	art/intro_by.1bpp \
	art/intro_reg.1bpp \
	art/intro_n0.1bpp \
	art/intro_i.1bpp \
	art/intro_n.1bpp \
	art/intro_t.1bpp \
	art/intro_e.1bpp \
	art/intro_d.1bpp \
	art/intro_o.1bpp \

all: $(TARGET)

clean:
	rm -f $(TARGET) $(SYM) $(OBJS) $(INTRO_1BPP)

$(TARGET): $(OBJS)
	$(RGBLINK) $(RGBLINKFLAGS) $^ -o $@
	$(RGBFIX) $(RGBFIXFLAGS) $@

src/intro.o: src/intro.asm $(INC) $(INTRO_1BPP)

%.o: %.asm $(INC)
	$(RGBASM) $(RGBASMFLAGS) $< -o $@

art/intro_%.1bpp: art/intro_%.png
	$(RGBGFX) -Z -d1 $< -o $@
