RGBLINK = rgblink
RGBFIX  = rgbfix
RGBASM  = rgbasm
RGBGFX  = rgbgfx

TITLE = NOTLICENSED
TARGET = intro.gbc
SYM = intro.sym

RGBLINKFLAGS = -n $(SYM)
RGBFIXFLAGS  = -v -p 0xFF -t $(TITLE) -c \
	--sgb-compatible --old-licensee 0x33

RGBASMFLAGS  = -I inc -I art
RGBASMFLAGS_INTRO = $(RGBASMFLAGS) -I art/intro \
	# -D INTRO_SONG=intro_song \
	# -D INTRO_SONG_DELAY=$10 \
	# -D COLOR8 \
	# -D GRADIENT \
	# -D FADEOUT \
	# -D EN_GB

OBJS = \
	src/start.o \
	src/intro/intro_main.o \
	src/intro/intro_copy.o \
	src/intro/intro_drop.o \
	src/intro/intro_lut.o \
	src/oamdma.o \
	src/sgb.o \
	# src/intro/intro_song.o \
	# src/hUGEDriver.o \
	
INC = \
	inc/hardware.inc \
	inc/common.inc \
	inc/color.inc \
	inc/gradient.inc \
	inc/sgb.inc \

INTRO_INC = \
	inc/intro.inc \

INTRO_1BPP = \
	art/intro/intro_not.1bpp \
	art/intro/intro_top.1bpp \
	art/intro/intro_by.1bpp \
	art/intro/intro_reg.1bpp \
	art/intro/intro_n0.1bpp \
	art/intro/intro_i.1bpp \
	art/intro/intro_n.1bpp \
	art/intro/intro_t.1bpp \
	art/intro/intro_e.1bpp \
	art/intro/intro_d.1bpp \
	art/intro/intro_o.1bpp \

INTRO_2BPP = \
	art/intro/intro_not.2bpp \
	art/intro/intro_top_0.2bpp \
	art/intro/intro_by.2bpp \

all: $(TARGET)

clean:
	rm -f $(TARGET) $(SYM) $(OBJS) $(INTRO_1BPP) $(INTRO_2BPP)

$(TARGET): $(OBJS)
	$(RGBLINK) $(RGBLINKFLAGS) $^ -o $@
	$(RGBFIX) $(RGBFIXFLAGS) $@

src/intro/intro_copy.o: src/intro/intro_copy.asm $(INC) $(INTRO_INC) $(INTRO_1BPP) $(INTRO_2BPP)

src/intro/%.o: src/intro/%.asm $(INC) $(INTRO_INC)
	$(RGBASM) $(RGBASMFLAGS_INTRO) $< -o $@

src/start.o: src/start.asm $(INC) $(INTRO_INC)
	$(RGBASM) $(RGBASMFLAGS_INTRO) $< -o $@

%.o: %.asm $(INC)
	$(RGBASM) $(RGBASMFLAGS) $< -o $@

art/intro/%.1bpp: art/intro/%.png
	$(RGBGFX) -Z -d1 $< -o $@

art/intro/%.2bpp: art/intro/%_gray.png
	$(RGBGFX) -c gbc:art/gray.pal $< -o $@
