# Compiler-Sessional-310

For offline-1 (SYMBOLTABLE) - run the 2105045_main.cpp file with 
"g++ -fsanitize=address -g -o 2105045_main 2105045_main.cpp" and then 
"./2105045_main sample_input.txt output.txt "

For offline-2 (Lexical Analysis) - run the 2105045.l file, here are the commands - 

"flex 2105045.l"
"g++ lex.yy.c"
"./a.out input.txt"

For offline-3 (Syntax and Semantic Analysis) - run the following commands - 
-"antlr4 -Dlanguage=Cpp -o generated C8086Lexer.g4"
-"antlr4 -Dlanguage=Cpp -o generated C8086Parser.g4"
-"g++ -std=c++17 -w -I/usr/local/include/antlr4-runtime -Igenerated generated/C8086Lexer.cpp generated/C8086Parser.cpp     Ctester.cpp     -L/usr/local/lib -lantlr4-runtime -o Ctester.out -pthread"

-"LD_LIBRARY_PATH=/usr/local/lib ./Ctester.out input/test3_i.c"

For offline-4 (ICG) - same as offline -3 


