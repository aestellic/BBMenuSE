; WRAM to SRAM offsets

; Bank 1
; sdmahijack:       $da80 -> $a000: offset = -$3A80 = -14976
; stopstack:        $da80 -> $a004: offset = -$3A7C = -14972
; scodebox:         $da80 -> $a042: offset = -$3A3E = -14910
; smenu:            $c6e8 -> $b524: offset = -$11c4 = -4548
; sblock1:          $c6e8+540=$c904 -> $b524+499=$b717: offset = -$11ed = -4589
; sblock2:          $c6e8+540=$c904 -> $b524+499+760=$ba0f: offset = -$0ef5 = -3829
; sblock3:          $c6e8+540=$c904 -> $b524+499+760+760=$bd07: offset = -$0bfd = -3069


; 8bit


; 16bit
def menulength           = $01f3   ; 499 bytes fixed
def blocklength          = $02f8   ; 760 bytes fixed

; rom0
def safejump             = $00b0
def bankswitch1          = $1135
def bankswitch3          = $074b
def bankswitch4          = $12d9
def bankswitch5          = $3dbd
def bankswitch15         = $329d
def bankswitch3c         = $0f50
def bankswitch3f         = $1001

; rom
def tileAddress          = $6a28
def slideSilhouettesLoop = $40c4
def hideSprites = (slideSilhouettesLoop + $39)
def animationLoop = $4139
def doBattleTransitionOffset = (DoBattleTransitionAndInitBattleVariables + $1E)

; sram
def sramcopy             = $a000
def srampokebuffer       = $bb80

; wram0
def nickwriterpointer    = $c7c2
def bufferdmaspare       = $c7af
def enabledmaspare       = $c7b4
def nickwriterdest       = $c800
def menu17txt            = $c820
def menu18txt            = $c82a
def menu19txt            = $c832
def menu20txt            = $c839
def menu21txt            = $c83e
def menu22txt            = $c844
def listable             = $c88a
def wmenulist            = $c8da
def wblock               = $c904
; common function block1
def createmenulist       = $c86a
def resetdmaspare        = $c86a+8
def initmenulist         = $c86a+8+6
def calcselect           = $c86a+8+6+8
; temporary menu pointer backup place
def gamesel              = $cf25
def bbmselect            = $cf27
def giverselect          = $cf29



; wram1
def wunused              = $d669
def mspinstruction       = $d6aa
def opensram1            = $d6e5
def opensramplus1        = $d6e6
def dmaflags             = $d700
def mspflags             = $d701
def bbmflags             = $d702
def escbackup            = $d703
def pongscore            = $d704
def snakescore           = $d705
def nicknameaddress      = $d8b4
def listaddress          = $d900

def savesel              = $db02
def loadsel              = $db0f
def dmatable             = $db1b
def msptable             = $db2b
def boxpayloads          = $db3b
def stackhijack          = $db44

def topstack             = $df15
def codeboxon            = $df2b

; hram
def rDIV                 = $ff04
def boxflag              = $ffa8   ; it holds current codebox status
def hbackup              = $ffdf   ; holds a value temporarily, used for various scripts


; sram offsets
def dmaoffset            = 14976
def stackoffset          = 14972
def boxoffset            = 14911             ; changes according to stack payload length
def menuoffset           = 4548
def block1offset         = 4589
def block2offset         = 3829
def block3offset         = 3069
def sdmahijack           = wBoxSpecies-dmaoffset
def stopstack            = wBoxSpecies-stackoffset
def scodebox             = wBoxSpecies-boxoffset
def smenu                = wOverworldMap-menuoffset  ; $b524
def sblock1              = wblock-block1offset
def sblock2              = wblock-block2offset
def sblock3              = wblock-block3offset
def smenulist            = wmenulist-menuoffset
def sdmatable            = dmatable-boxoffset
def smsptable            = msptable-boxoffset
def slistable            = listable-menuoffset
def sboxpayloads         = boxpayloads-boxoffset






