#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <stack>
#include "antlr4-runtime.h"
#include "C8086Lexer.h"
#include "C8086Parser.h"

using namespace antlr4;
using namespace std;




ofstream parserLogFile;
ofstream errorFile;
ofstream lexLogFile;
ofstream asmFile;
ofstream optimizedAsmFile;


int syntaxErrorCount = 0;
int labelCount = 0;
int tempCount = 0;


SymbolTable* symbolTable = nullptr;
map<string, int> variableOffsets;
int currentOffset = 0;
vector<string> globalVariables;


string currentFunctionName = "";
string currentFunctionReturnType = "";
bool isInFunction = false;
int compoundDepth = 0;
bool dataSectionGenerated = false;
bool hasReturnStatement = false;
bool isDeclarationPass = false;


stack<string> parameterStack;


stack<string> operatorStack;
stack<string> labelStack;
stack<string> contextStack;
stack<bool> arrayAccessStack;

int main(int argc, const char* argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        return 1;
    }

    // ---- Input File ----
    ifstream inputFile(argv[1]);
    if (!inputFile.is_open()) {
        cerr << "Error opening input file: " << argv[1] << endl;
        return 1;
    }

    string outputDirectory = "output/";
    string parserLogFileName = outputDirectory + "parserLog.txt";
    string errorFileName = outputDirectory + "errorLog.txt";
    string lexLogFileName = outputDirectory + "lexerLog.txt";
    string asmFileName = outputDirectory + "code.asm";
    string optimizedAsmFileName = outputDirectory + "optimized_code.asm";

   
    system(("mkdir -p " + outputDirectory).c_str());

    // ---- Output Files ----
    parserLogFile.open(parserLogFileName);
    if (!parserLogFile.is_open()) {
        cerr << "Error opening parser log file: " << parserLogFileName << endl;
        return 1;
    }

    errorFile.open(errorFileName);
    if (!errorFile.is_open()) {
        cerr << "Error opening error log file: " << errorFileName << endl;
        return 1;
    }

    lexLogFile.open(lexLogFileName);
    if (!lexLogFile.is_open()) {
        cerr << "Error opening lexer log file: " << lexLogFileName << endl;
        return 1;
    }

    asmFile.open(asmFileName);
    if (!asmFile.is_open()) {
        cerr << "Error opening assembly file: " << asmFileName << endl;
        return 1;
    }

    optimizedAsmFile.open(optimizedAsmFileName);
    if (!optimizedAsmFile.is_open()) {
        cerr << "Error opening optimized assembly file: " << optimizedAsmFileName << endl;
        return 1;
    }
   
   
    ANTLRInputStream input(inputFile);
    C8086Lexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    C8086Parser parser(&tokens);

   
    parser.removeErrorListeners();

  
    syntaxErrorCount = 0;
    labelCount = 0;
    tempCount = 0;
    symbolTable = nullptr;
    currentOffset = 0;
    isInFunction = false;
   
    while (!operatorStack.empty()) operatorStack.pop();
    while (!labelStack.empty()) labelStack.pop();
    while (!contextStack.empty()) contextStack.pop();
    while (!arrayAccessStack.empty()) arrayAccessStack.pop();
    while (!parameterStack.empty()) parameterStack.pop();

   
    parser.start();

 
    inputFile.close();
    parserLogFile.close();
    errorFile.close();
    lexLogFile.close();
    asmFile.close();
    optimizedAsmFile.close();
    
 
    if (symbolTable) {
        delete symbolTable;
    }
    
    cout << "Parsing completed. Check the output files for details." << endl;
    return 0;
}
