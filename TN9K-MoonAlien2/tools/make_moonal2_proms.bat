copy /b ali1 + ali2 + ali3 + ali4 + ali5 + ali6 + ali7 + ali8 + ali9 + ali10 + ali11 main.bin

make_vhdl_prom main.bin ROM_PRG_0.vhd
make_vhdl_prom 6l.bpr GALAXIAN_6l.vhd
make_vhdl_prom ali13.1h GALAXIAN_1h.vhd
make_vhdl_prom ali12.1k GALAXIAN_1k.vhd

pause
