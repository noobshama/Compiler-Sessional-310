%option noyywrap



%{
 
#include<iostream>
#include<fstream>
#include<string>
#include<sstream>
#include "2105045_symbolTable.cpp"
#include "2105045_symbolInfo.cpp"
using namespace std;

int errorCount = 0;
int lineCount = 1;

string actualString;
string modifiedString;


string actualChar;
string modifiedChar;

string actualComment;
string modifiedComment;


int startLine;


SymbolTable symbolTable(7);

FILE *fin;
FILE *logFile;
FILE *tokenFile;


string modifyEse(string str)
{
    char ch = str[1]; 

    switch (ch)
    {
        case 't': 
             return "\t";
        case 'n': 
             return "\n";
        case '\\': 
             return "\\";
        case '\'': 
             return "\'";
        case '\"': 
             return "\"";
        case 'a': 
             return "\a";
        case 'f': 
             return "\f";
        case 'r': 
             return "\r";
        case 'b': 
             return "\b";
        case 'v': 
             return "\v";
        case '0': 
             return string(1, '\0');
        default: 
             return "x";  
    }
}

void appendEscapeSequence(const char* seq) {
    actualString += seq;
    modifiedString += modifyEse(seq);
}

void reportUnterminatedString() {
    fprintf(logFile, "Error at line no %d: Unterminated string %s\n", startLine, actualString.c_str());
    fprintf(logFile, "\n");
    errorCount++;
}
void reportUnterminatedStringLine() {
    fprintf(logFile, "Error at line no %d: Unterminated string %s\n", lineCount, actualString.c_str());
    fprintf(logFile, "\n");
    errorCount++;
}

void appendCharEscapeSequence(const char* seq) {
    actualChar += seq;
    modifiedChar += modifyEse(seq);
}

void validateCharLiteral() {
    if (modifiedChar.length() == 0) {
        fprintf(logFile, "Error at line no %d: Empty character constant error %s\n", lineCount, actualChar.c_str());
        fprintf(logFile, "\n");
        fprintf(logFile,"\n");
        errorCount++;
    }
    else if (modifiedChar.length() > 1) {
        fprintf(logFile, "Error at line no %d: Multi character constant error %s\n", lineCount, actualChar.c_str());
        fprintf(logFile, "\n");
        fprintf(logFile,"\n");
        errorCount++;
    }
    else {
        fprintf(tokenFile, "<CONST_CHAR, %s> ", modifiedChar.c_str());
        fprintf(logFile, "Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR, %s>\n", lineCount, actualChar.c_str(), modifiedChar.c_str());
        fprintf(logFile, "\n");
        if(symbolTable.Insert(actualChar.c_str(), "CONST_CHAR")) {
            symbolTable.printAllScopes(logFile);
        }
    }
}

void reportUnterminatedChar() {
    fprintf(logFile, "Error at line no %d: Unterminated character %s\n", lineCount, actualChar.c_str());
    fprintf(logFile, "\n");
    fprintf(logFile,"\n");
    errorCount++;
}

void finishLineComment() {
    fprintf(logFile, "Line no %d: Token <COMMENT> Lexeme %s found\n", lineCount, actualComment.c_str());
    fprintf(logFile, "\n");
}

void finishBlockComment() {
    fprintf(logFile, "Line no %d: Token <COMMENT> Lexeme %s found\n", lineCount, actualComment.c_str());
    fprintf(logFile, "\n");
}

void reportUnterminatedComment() {
    fprintf(logFile, "Error at line no %d: Unterminated comment %s\n", startLine, actualComment.c_str());
    fprintf(logFile, "\n");
    errorCount++;
}
%}

%x STRING
%x CHAR
%x LINE_COMMENT
%x COMMENT

DIGIT [0-9]
CONST_INT {DIGIT}+

CONST_FLOAT {DIGIT}*(\.{DIGIT}+)?([Ee][+-]?{DIGIT}+)?

LETTER [a-zA-Z_]
ID {LETTER}({LETTER}|{DIGIT})*

NEWLINE \n

WHITESPACE [ \t\f\r\v]+

DECIMALPOINT {DIGIT}*(\.{DIGIT}*)(\.{DIGIT}*)+([Ee][+-]?{DIGIT}*(\.{DIGIT}*)*)?
ILLFORMEDNUMBER {DIGIT}*(\.{DIGIT}*)?([Ee][+-]?{DIGIT}*(\.{DIGIT}*)*)

INVALID {DIGIT}+({ID}+)

ESCAPE_SEQUENCE \\[tn\\'afbrv0]

UNRECOGNIZED_CHAR .





%%

{WHITESPACE} {}
{NEWLINE}  { 


    lineCount++;
}

"if" {

 fprintf(tokenFile, "<IF> ");
 fprintf(logFile, "Line no %d: Token <IF> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"else" {
 fprintf(tokenFile, "<ELSE, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <ELSE> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"goto" {
 fprintf(tokenFile, "<GOTO, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <GOTO> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"for" {
 fprintf(tokenFile, "<FOR, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <FOR> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"while" {
 fprintf(tokenFile, "<WHILE, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <WHILE> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"long" {
 fprintf(tokenFile, "<LONG> ");
 fprintf(logFile, "Line no %d: Token <LONG> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"do" {
 fprintf(tokenFile, "<DO, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <DO> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"break" {
 fprintf(tokenFile, "<BREAK, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <BREAK> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"short" {
 fprintf(tokenFile, "<SHORT> ");
 fprintf(logFile, "Line no %d: Token <SHORT> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"int" {
 fprintf(tokenFile, "<INT> ");
 fprintf(logFile, "Line no %d: Token <INT> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"char" {    
 fprintf(tokenFile, "<CHAR> ");
 fprintf(logFile, "Line no %d: Token <CHAR> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"static" {
 fprintf(tokenFile, "<STATIC, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <STATIC> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"float" {
 fprintf(tokenFile, "<FLOAT> ");
 fprintf(logFile, "Line no %d: Token <FLOAT> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"double" {
 fprintf(tokenFile, "<DOUBLE> ");
 fprintf(logFile, "Line no %d: Token <DOUBLE> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"unsigned" {
 fprintf(tokenFile, "<UNSIGNED> ");
 fprintf(logFile, "Line no %d: Token <UNSIGNED> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"void" {
 fprintf(tokenFile, "<VOID, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <VOID> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"return" {
 fprintf(tokenFile, "<RETURN> ");
 fprintf(logFile, "Line no %d: Token <RETURN> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"switch" {
 fprintf(tokenFile, "<SWITCH, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <SWITCH> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"case" {
 fprintf(tokenFile, "<CASE, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <CASE> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"default" {
 fprintf(tokenFile, "<DEFAULT, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <DEFAULT> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"continue" {
 fprintf(tokenFile, "<CONTINUE, %s> ", yytext); 
 fprintf(logFile, "Line no %d: Token <CONTINUE> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}

"+"|"-" {
  fprintf(tokenFile, "<ADDOP, %s> ", yytext);
  fprintf(logFile, "Line no %d: Token <ADDOP> Lexeme %s found\n", lineCount, yytext);
  fprintf(logFile, "\n");
}
"*"|"\/"|"%" {
 fprintf(tokenFile, "<MULOP, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <MULOP> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}

"++"|"--" {
 fprintf(tokenFile, "<INCOP, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <INCOP> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"<"|"<="|">"|">="|"=="|"!=" {
 fprintf(tokenFile, "<RELOP, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <RELOP> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"=" {
 fprintf(tokenFile, "<ASSIGNOP, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <ASSIGNOP> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"&&"|"||" {
 fprintf(tokenFile, "<LOGICOP, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <LOGICOP> Lexeme %s found\n",lineCount, yytext);
 fprintf(logFile, "\n");
}
"!" {
 fprintf(tokenFile, "<NOT, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <NOT> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"(" {
 fprintf(tokenFile, "<LPAREN, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <LPAREN> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
")" {
 fprintf(tokenFile, "<RPAREN, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <RPAREN> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"{" {
    fprintf(tokenFile, "<LCURL, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <LCURL> Lexeme %s found\n", lineCount, yytext);
    symbolTable.EnterScope(7,   symbolTable.getCurrentScopeId());
    fprintf(logFile, "\n");
}
"}" {
    fprintf(tokenFile, "<RCURL, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <RCURL> Lexeme %s found\n", lineCount, yytext);
    symbolTable.ExitScope();
    fprintf(logFile, "\n");
}
"[" {
 fprintf(tokenFile, "<LTHIRD, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <LTHIRD> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"]" {
 fprintf(tokenFile, "<RTHIRD, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <RTHIRD> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
"," {
 fprintf(tokenFile, "<COMMA, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <COMMA> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
";" {
 fprintf(tokenFile, "<SEMICOLON, %s> ", yytext);
 fprintf(logFile, "Line no %d: Token <SEMICOLON> Lexeme %s found\n", lineCount, yytext);
 fprintf(logFile, "\n");
}
{ID} {
    fprintf(tokenFile,"<ID, %s> ", yytext);
    fprintf(logFile,"Line no %d: Token <ID> Lexeme %s found\n", lineCount, yytext);
    fprintf(logFile, "\n");
    if(symbolTable.Insert(yytext, "ID")) {
           
           symbolTable.printAllScopes(logFile);
         
         } 
    else {
      
        SymbolInfo *symbolInfo = symbolTable.LookUp(yytext);
      
         //fprintf(logFile,"\t%s already exists in the current ScopeTable\n", yytext); 
         fprintf(logFile, "< %s : ID > already exists in ScopeTable# %s at position %d, %d", yytext, symbolTable.getCurrentScopeId().c_str(),symbolInfo->getHashIndex(),symbolInfo->getLinkedListIndex());
         fprintf(logFile, "\n");
         fprintf(logFile, "\n");
 

    }
}
{CONST_INT} {

    fprintf(tokenFile,"<CONST_INT, %s> ", yytext);
    fprintf(logFile,"Line no %d: Token <CONST_INT> Lexeme %s found\n", lineCount, yytext);
    fprintf(logFile, "\n");
    if(symbolTable.Insert(yytext, "CONST_INT")) {
           
           symbolTable.printAllScopes(logFile);
         
         } 
    else {
        SymbolInfo *symbolInfo = symbolTable.LookUp(yytext);
      
         //fprintf(logFile,"\t%s already exists in the current ScopeTable\n", yytext); 
         fprintf(logFile, "< %s : CONST_INT > already exists in ScopeTable# %s at position %d, %d", yytext,symbolTable.getCurrentScopeId().c_str(),symbolInfo->getHashIndex(),symbolInfo->getLinkedListIndex());
         fprintf(logFile, "\n");
         fprintf(logFile, "\n");

    }
}
{CONST_FLOAT} {
    fprintf(tokenFile,"<CONST_FLOAT, %s> ", yytext);
    fprintf(logFile,"Line no %d: Token <CONST_FLOAT> Lexeme %s found\n", lineCount, yytext);
    fprintf(logFile, "\n");
    if(symbolTable.Insert(yytext, "CONST_FLOAT")) {
           
           symbolTable.printAllScopes(logFile);
         
         } 
    else {
      
       SymbolInfo *symbolInfo = symbolTable.LookUp(yytext);
      
         //fprintf(logFile,"\t%s already exists in the current ScopeTable\n", yytext); 
         fprintf(logFile, "< %s : CONST_FLOAT > already exists in ScopeTable# %s at position %d, %d", yytext, symbolTable.getCurrentScopeId().c_str(),symbolInfo->getHashIndex(),symbolInfo->getLinkedListIndex());
         fprintf(logFile, "\n");
         fprintf(logFile, "\n");

    }
}
{DECIMALPOINT} {
    
    fprintf(logFile,"Error at line no %d: Too many decimal points %s\n", lineCount, yytext);
    fprintf(logFile, "\n");
    fprintf(logFile,"\n");
    errorCount++;
}
{ILLFORMEDNUMBER} {
    
    fprintf(logFile,"Error at line no %d: Ill formed number %s\n", lineCount, yytext);
    fprintf(logFile, "\n");
    fprintf(logFile,"\n");
    errorCount++;
}
{INVALID} {
    fprintf(logFile,"Error at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n", lineCount, yytext);
    fprintf(logFile, "\n");
    errorCount++;
}

\" {
    BEGIN(STRING);
    actualString = yytext;
    modifiedString = yytext;
    startLine = lineCount;
}

<STRING>{
    \" {
        actualString += yytext;
        modifiedString +=yytext;
        string content = (actualString.size() > 2) ? modifiedString.substr(1, modifiedString.size() - 2) : actualString;
        fprintf(tokenFile, "<STRING, %s> ", content.c_str());
        fprintf(logFile, "Line no %d: Token <STRING> Lexeme %s found --> <STRING, %s>\n",lineCount, actualString.c_str(), content.c_str());
        fprintf(logFile, "\n");
        BEGIN(INITIAL);
    }

    {ESCAPE_SEQUENCE} {
        appendEscapeSequence(yytext);
    }

    \\{NEWLINE} {
        actualString += yytext;
        lineCount++;
    }

    {NEWLINE} {
        reportUnterminatedString();
        lineCount++;
        BEGIN(INITIAL);
    }
    "\\\"" {

        modifiedString += "\"";
        actualString += yytext;
    }
    <<EOF>> {
        reportUnterminatedStringLine();
        BEGIN(INITIAL);
    }

    . {
        actualString += yytext;
        modifiedString += yytext;
    }
}

\' {
    BEGIN(CHAR);
    actualChar = "'";
    modifiedChar = "";
    startLine = lineCount;
}

<CHAR>{
    \' {
        actualChar += yytext;
        validateCharLiteral();
        BEGIN(INITIAL);
    }

    {ESCAPE_SEQUENCE} {
        appendCharEscapeSequence(yytext);
    }

    {NEWLINE} {
        reportUnterminatedChar();
        lineCount++;
        BEGIN(INITIAL);
    }

    <<EOF>> {
        reportUnterminatedChar();
        lineCount++;
        BEGIN(INITIAL);
    }

    . {
        actualChar += yytext;
        modifiedChar += yytext;
    }
}

"//" {
    BEGIN(LINE_COMMENT);
    actualComment = yytext;
}

<LINE_COMMENT>{
    \\{NEWLINE} {

        lineCount++;
        actualComment += yytext;
    }
    {NEWLINE} {
        finishLineComment();
        lineCount++;
        BEGIN(INITIAL);
    }
    . {
        actualComment += yytext;
    }
}

"/*" {
    BEGIN(COMMENT);
    actualComment = yytext;
    startLine = lineCount;
}

<COMMENT>{
    "*/" {
        actualComment += yytext;
        finishBlockComment();
        BEGIN(INITIAL);
    }

    {NEWLINE} {
        lineCount++;
        actualComment += yytext;
    }

    <<EOF>> {
        reportUnterminatedComment();
        BEGIN(INITIAL);
    }

    . {
        actualComment += yytext;
    }
}

{UNRECOGNIZED_CHAR} {
    errorCount++;
    fprintf(logFile,"Error at line no %d: Unrecognized character %s\n", lineCount, yytext);
    fprintf(logFile, "\n");
}


%%

int main(int argc, char const* argv[]) {
    if(argc!=2){
      printf("Please provide input file name and try again\n");
      return 0;
    }

    fin=fopen(argv[1],"r");
    if(fin==NULL){
      printf("Cannot open specified file\n");
      return 0;
    }


    logFile= fopen("log.txt","w");
    tokenFile= fopen("token.txt","w");

    yyin= fin;
    yylex();

   
    
    symbolTable.printAllScopes(logFile);
    
    fprintf(logFile,"Total lines: %d\n", lineCount);
    fprintf(logFile,"Total errors: %d\n", errorCount);
    fclose(yyin);
    fclose(tokenFile);
    fclose(logFile);
    return 0;
}






