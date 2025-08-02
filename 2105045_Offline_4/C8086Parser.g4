parser grammar C8086Parser;

options {
    tokenVocab = C8086Lexer;
}

@parser::header {
    #include <iostream>
    #include <fstream>
    #include <string>
    #include <cstdlib>
    #include <vector>
    #include <map>
    #include <stack>
    #include <sstream>
    #include <algorithm>
    #include "C8086Lexer.h"
    #include "2105045_symbolTable.cpp"
    #include "2105045_functionInfo.cpp"

    extern std::ofstream parserLogFile;
    extern std::ofstream errorFile;
    extern std::ofstream asmFile;
    extern std::ofstream optimizedAsmFile;

    extern int syntaxErrorCount;
    extern int labelCount;
    extern int tempCount;
    extern SymbolTable* symbolTable;

    extern std::map<std::string, int> variableOffsets;
    extern int currentOffset;
    extern std::vector<std::string> globalVariables;
    extern std::string currentFunctionName;
    extern std::string currentFunctionReturnType;
    extern bool isInFunction;
    extern std::stack<std::string> parameterStack;
    extern int compoundDepth;
    extern bool dataSectionGenerated;
    extern bool hasReturnStatement;
    
    extern std::stack<std::string> operatorStack;
    extern std::stack<std::string> labelStack;
    extern std::stack<std::string> contextStack;
    extern std::stack<bool> arrayAccessStack;



}

@parser::members {

    // to store the asmcode
    std::vector<std::string> generatedCode;
    void writeIntoparserLogFile(const std::string message)
     {
        if (!parserLogFile) {
            std::cout << "Error opening parserLogFile.txt" << std::endl;
            return;
        }

        parserLogFile << message << std::endl;
        parserLogFile.flush();
    }

    void writeIntoErrorFile(const std::string message) {
        if (!errorFile) {
            std::cout << "Error opening errorFile.txt" << std::endl;
            return;
        }
        errorFile << message << std::endl;
        errorFile.flush();
    }
    void emit(const std::string &code) 
    {
        if (asmFile.is_open()) 
        {
            asmFile << code << std::endl;
            asmFile.flush();
        }
        // Stored all generated code for optimization
        generatedCode.push_back(code);
    }


std::string trim(const std::string& str)
{
    size_t start = str.find_first_not_of(" \t\r\n");

    if (start == std::string::npos)
    { 
        return "";
    }
    size_t end = str.find_last_not_of(" \t\r\n");

    return str.substr(start, end - start + 1);
}


bool isConsecutiveMovPattern(const std::string& line1, const std::string& line2) 
{
    std::string l1 = trim(line1);
    std::string l2 = trim(line2);
    
 
    size_t mov1Pos = l1.find("MOV ");
    size_t mov2Pos = l2.find("MOV AX, ");
    
    if (mov1Pos == std::string::npos || mov2Pos == std::string::npos) 
    {
        return false;
    }
    
    
    size_t axPos = l1.find(", AX");
    if (axPos == std::string::npos) 
    {
        return false;
    }
    
 
    std::string dest = l1.substr(mov1Pos + 4, axPos - (mov1Pos + 4));
    
  
    std::string src = l2.substr(mov2Pos + 8); // Skip "MOV AX, "
    
   
    dest.erase(std::remove(dest.begin(), dest.end(), ' '), dest.end());
    src.erase(std::remove(src.begin(), src.end(), ' '), src.end());
    
    
    // std::cout << "Comparing: '" << dest << "' vs '" << src << "'" << std::endl;
    
    return dest == src;
}


bool isRedundantMovWithSkip(const std::vector<std::string>& code, size_t storeIndex, size_t& loadIndex) 

{
    std::string storeLine = trim(code[storeIndex]);
    
   
    if (storeLine.find("MOV ") == std::string::npos || storeLine.find(", AX") == std::string::npos) 
    {
        return false;
    }
    
  
    size_t movPos = storeLine.find("MOV ");

    size_t axPos = storeLine.find(", AX");

    std::string destination = storeLine.substr(movPos + 4, axPos - (movPos + 4));

    destination.erase(std::remove(destination.begin(), destination.end(), ' '), destination.end());
    
 
    for (size_t i = storeIndex + 1; i < std::min(storeIndex + 8, code.size()); i++) 
    {
        std::string currentLine = trim(code[i]);
        
        
        if (currentLine.empty() || currentLine[0] == ';')
        {
            continue;
        }
        
       
        if (currentLine.find("JMP") != std::string::npos || currentLine.find("JE ") != std::string::npos || currentLine.find("JNE ") != std::string::npos || currentLine.find("JL ") != std::string::npos || currentLine.find("JG ") != std::string::npos || currentLine.find("JLE ") != std::string::npos || currentLine.find("JGE ") != std::string::npos || currentLine.find("CALL") != std::string::npos || currentLine.find("RET") != std::string::npos) 
        {
           
            return false;
        }
        
        
        if (currentLine.back() == ':')
        {
           
            return false;
        }
        
      
        if (currentLine.find("MOV AX,") == std::string::npos && (currentLine.find("ADD AX") != std::string::npos || currentLine.find("SUB AX") != std::string::npos || currentLine.find("MUL") != std::string::npos || currentLine.find("DIV") != std::string::npos || currentLine.find("NEG AX") != std::string::npos || currentLine.find("POP AX") != std::string::npos || currentLine.find("INC") != std::string::npos || currentLine.find("DEC") != std::string::npos)) 
        {
            return false;
        }
        
      
        if (currentLine.find("MOV AX, ") != std::string::npos) 
        {
            size_t loadMovPos = currentLine.find("MOV AX, ");

            std::string source = currentLine.substr(loadMovPos + 8); 

            source.erase(std::remove(source.begin(), source.end(), ' '), source.end());
            
            if (destination == source) 
            {
                loadIndex = i;
                return true; 
            }
        }
        
      
        if (currentLine.find("MOV ") != std::string::npos) 
        {
            return false;
        }
    }
    
    return false;
}



bool isRedundantArithmeticOperation(const std::vector<std::string>& code, size_t index) 

{
    if (index + 1 >= code.size()) return false;
    
    std::string line1 = trim(code[index]);     
    std::string line2 = trim(code[index + 1]); 
    
    
    auto extractInstruction = [](const std::string& line) 
    
    {
        size_t commentPos = line.find(';');

        std::string instruction = (commentPos != std::string::npos) ? line.substr(0, commentPos) : line;
       
        size_t start = instruction.find_first_not_of(" \t");

        if (start == std::string::npos) return std::string("");

        size_t end = instruction.find_last_not_of(" \t");

        return instruction.substr(start, end - start + 1);
    };
    
    std::string inst1 = extractInstruction(line1);
    std::string inst2 = extractInstruction(line2);
    
    
    if (inst1 == "MOV BX, 0" && inst2 == "ADD AX, BX") 
    {
        return true;
    }
    
   
    if (inst1 == "MOV BX, 0" && inst2 == "SUB AX, BX") 
    {
        return true;
    }
    
   
    if (inst1 == "MOV BX, 1" && inst2 == "MUL BX") 
    {
        return true;
    }
    
    return false;
}



std::string getArithmeticDescription(const std::vector<std::string>& code, size_t index) 
{
    auto extractInstruction = [](const std::string& line) 
    {
        size_t commentPos = line.find(';');

        std::string instruction = (commentPos != std::string::npos) ? line.substr(0, commentPos) : line;

        size_t start = instruction.find_first_not_of(" \t");

        if (start == std::string::npos) return std::string("");

        size_t end = instruction.find_last_not_of(" \t");

        return instruction.substr(start, end - start + 1);
    };
    
    std::string inst1 = extractInstruction(code[index]);
    std::string inst2 = extractInstruction(code[index + 1]);
    
    if (inst1 == "MOV BX, 0" && inst2 == "ADD AX, BX")
    {
        return "ADD AX, 0";
    } 
    else if (inst1 == "MOV BX, 0" && inst2 == "SUB AX, BX") 
    {
        return "SUB AX, 0";
    } 
    else if (inst1 == "MOV BX, 1" && inst2 == "MUL BX") 
    {
        return "MUL AX, 1";
    }
    return "unknown arithmetic";
}









void writeOptimizedCode() 
{
    
    if (asmFile.is_open())
    {
        asmFile.flush();
    }
    
    if (!optimizedAsmFile.is_open()) 
    {
        std::cout << "Warning: optimizedAsmFile is not open!" << std::endl;
        return;
    }
    
    if (generatedCode.empty()) 
    {
        std::cout << "Warning: generatedCode is empty!" << std::endl;
        return;
    }
    
    std::vector<std::string> optimized = optimizeCode(generatedCode);
    
    
    
    
    
    for (const auto& line : optimized) {
        optimizedAsmFile << line << std::endl;
    }
    optimizedAsmFile.flush();
    
    std::cout << "Optimization completed. Check optimized.asm file." << std::endl;
}


void debugOptimization() 
{
    std::cout << "=== OPTIMIZATION DEBUG ===" << std::endl;
    std::cout << "Generated code lines: " << generatedCode.size() << std::endl;
    std::cout << "OptimizedAsmFile open: " << optimizedAsmFile.is_open() << std::endl;
    
   
    for (size_t i = 0; i < std::min(generatedCode.size(), size_t(50)); i++) 
    {
        std::string line = trim(generatedCode[i]);
        if (line.find("MOV ") != std::string::npos) 
        {
            std::cout << "MOV found at line " << i << ": " << line << std::endl;
        }
    }
    std::cout << "=========================" << std::endl;
}



bool isRedundantPushPopPattern(const std::vector<std::string>& code, size_t startIdx) 
{
    if (startIdx + 3 >= code.size()) 
    {
        return false;
    }

    std::string line1 = trim(code[startIdx]);     
    std::string line2 = trim(code[startIdx + 1]); 
    std::string line3 = trim(code[startIdx + 2]); 
    std::string line4 = trim(code[startIdx + 3]); 
    
   
    // std::cout << "Checking pattern at " << startIdx << ":" << std::endl;
    // std::cout << "  Line1: '" << line1 << "'" << std::endl;
    // std::cout << "  Line2: '" << line2 << "'" << std::endl;
    // std::cout << "  Line3: '" << line3 << "'" << std::endl;
    // std::cout << "  Line4: '" << line4 << "'" << std::endl;
    
    // More flexible pattern matching for PUSH/POP optimization
    bool isPushAX = (line1 == "PUSH AX");
    bool isMovAX = (line2.find("MOV AX, ") != std::string::npos);
    bool isMovBXAX = (line3 == "MOV BX, AX");
    bool isPopAX = (line4 == "POP AX");
    
    return isPushAX && isMovAX && isMovBXAX && isPopAX;
}


bool isConsecutivePushPop(const std::string& line1, const std::string& line2) 
{
    std::string l1 = trim(line1);
    std::string l2 = trim(line2);
    
    return ((l1 == "PUSH AX" && l2 == "POP AX") || (l1 == "PUSH BX" && l2 == "POP BX") || (l1 == "PUSH CX" && l2 == "POP CX") || (l1 == "PUSH DX" && l2 == "POP DX"));
}


std::string extractMovValue(const std::string& line) 
{
    std::string trimmed = trim(line);

    size_t pos = trimmed.find("MOV AX, ");

    if (pos != std::string::npos) 
    {
        return trimmed.substr(pos + 8); 
    }
    return "";
}



bool hasConsecutiveLabels(const std::vector<std::string>& code, size_t startIdx, std::vector<size_t>& labelIndices) 
{
    labelIndices.clear();
    
    
    for (size_t i = startIdx; i < code.size(); i++) 
    {
        std::string line = trim(code[i]);
        
        if (!line.empty() && line.back() == ':') 
        {
            labelIndices.push_back(i);
        } 
        else if (!line.empty() && line[0] != ';')
        {
           
            break;
        }
    }
    
    return labelIndices.size() > 1; 
}


std::string extractLabelName(const std::string& line) 
{
    std::string trimmed = trim(line);
    if (!trimmed.empty() && trimmed.back() == ':') 
    {
        return trimmed.substr(0, trimmed.length() - 1);
    }
    return "";
}


void redirectLabelReferences(std::vector<std::string>& code, const std::string& oldLabel, const std::string& newLabel) 
{
    for (auto& line : code) 
    {
        std::string trimmed = trim(line);
        
       
        if (trimmed.find("JMP " + oldLabel) != std::string::npos) 
        {
            size_t pos = line.find("JMP " + oldLabel);
            line.replace(pos, ("JMP " + oldLabel).length(), "JMP " + newLabel);
        }
        else if (trimmed.find("JE " + oldLabel) != std::string::npos) 
        {
            size_t pos = line.find("JE " + oldLabel);
            line.replace(pos, ("JE " + oldLabel).length(), "JE " + newLabel);
        }
        else if (trimmed.find("JNE " + oldLabel) != std::string::npos) 
        {
            size_t pos = line.find("JNE " + oldLabel);
            line.replace(pos, ("JNE " + oldLabel).length(), "JNE " + newLabel);
        }
        else if (trimmed.find("JL " + oldLabel) != std::string::npos) 
        {
            size_t pos = line.find("JL " + oldLabel);
            line.replace(pos, ("JL " + oldLabel).length(), "JL " + newLabel);
        }
        else if (trimmed.find("JG " + oldLabel) != std::string::npos) 
        {
            size_t pos = line.find("JG " + oldLabel);
            line.replace(pos, ("JG " + oldLabel).length(), "JG " + newLabel);
        }
        else if (trimmed.find("JLE " + oldLabel) != std::string::npos) 
        {
            size_t pos = line.find("JLE " + oldLabel);
            line.replace(pos, ("JLE " + oldLabel).length(), "JLE " + newLabel);
        }
        else if (trimmed.find("JGE " + oldLabel) != std::string::npos) 
        {
            size_t pos = line.find("JGE " + oldLabel);
            line.replace(pos, ("JGE " + oldLabel).length(), "JGE " + newLabel);
        }
    }
}



std::vector<std::string> optimizeCode(const std::vector<std::string>& code) 
{
    std::vector<std::string> result;

    int movOptimizations = 0;

    int pushPopOptimizations = 0;

    int arithmeticOptimizations = 0;

    int labelOptimizations = 0; 
    

    for (size_t i = 0; i < code.size(); i++) 
    {
        
     
        if (isRedundantPushPopPattern(code, i))
        {
            std::string movValue = extractMovValue(code[i + 1]);
            result.push_back("    MOV BX, " + movValue + "    ; Optimized: PUSH/POP pattern eliminated");
            pushPopOptimizations++;
            i += 3;
            continue;
        }
        
     
        if (i + 1 < code.size() && isConsecutivePushPop(code[i], code[i + 1])) 
        {
            result.push_back("    ; Optimized: Useless PUSH/POP pair removed");
            pushPopOptimizations++;
            i++; 
            continue;
        }
        
      
        size_t loadIndex;
        if (isRedundantMovWithSkip(code, i, loadIndex)) 
        {
            result.push_back(code[i]); 
            for (size_t k = i + 1; k < loadIndex; k++) 
            {
                result.push_back(code[k]);
            }
            result.push_back("    ; Optimized: Redundant MOV removed - " + trim(code[loadIndex]));

            movOptimizations++;

            i = loadIndex; 

            continue;
        }
        
       
        if (i + 1 < code.size() && isConsecutiveMovPattern(code[i], code[i + 1])) 
        {
            result.push_back(code[i]);  // Keep first MOV (store)
            result.push_back("    ; Optimized: Simple redundant MOV removed");
            movOptimizations++;
            i++; // Skip second MOV (redundant load)
            continue;
        }
        
        result.push_back(code[i]);
    }
  

    std::vector<std::string> secondPass;
    for (size_t i = 0; i < result.size(); i++)
    {
        
      
        if (i + 1 < result.size() && isRedundantArithmeticOperation(result, i)) 
        {
            secondPass.push_back("    ; Optimized: Redundant arithmetic removed - " + 
                                 getArithmeticDescription(result, i));
            arithmeticOptimizations++;
            i++; // Skip both MOV BX and arithmetic instruction
            continue;
        }
        
        secondPass.push_back(result[i]);
    }
    
   
    std::vector<std::string> finalResult;
    for (size_t i = 0; i < secondPass.size(); i++)
    {
        
        std::vector<size_t> labelIndices;
        if (hasConsecutiveLabels(secondPass, i, labelIndices)) 
        {
            
          
            std::string keepLabel = extractLabelName(secondPass[labelIndices[0]]);
            finalResult.push_back(secondPass[labelIndices[0]]); 
            
           
            for (size_t j = 1; j < labelIndices.size(); j++) 
            {
                std::string redundantLabel = extractLabelName(secondPass[labelIndices[j]]);
                finalResult.push_back("    ; Optimized: Redundant label removed - " + redundantLabel + ":");
                
               
                redirectLabelReferences(finalResult, redundantLabel, keepLabel);
                labelOptimizations++;
            }
            
            i = labelIndices.back(); 
            continue;
        }
        
        finalResult.push_back(secondPass[i]);
    }
    
  
    if (movOptimizations > 0 || pushPopOptimizations > 0 || arithmeticOptimizations > 0 || labelOptimizations > 0) 
    {
        finalResult.push_back("; ===== OPTIMIZATION SUMMARY =====");

        finalResult.push_back("; Redundant MOV patterns removed: " + std::to_string(movOptimizations));

        finalResult.push_back("; Redundant PUSH/POP patterns removed: " + std::to_string(pushPopOptimizations));

        finalResult.push_back("; Redundant arithmetic operations removed: " + std::to_string(arithmeticOptimizations));

        finalResult.push_back("; Redundant labels removed: " + std::to_string(labelOptimizations));

        finalResult.push_back("; Total optimizations: " + std::to_string(movOptimizations + pushPopOptimizations + arithmeticOptimizations + labelOptimizations));
        
        int instructionsSaved = movOptimizations + (pushPopOptimizations * 3) + (arithmeticOptimizations * 2);

        finalResult.push_back("; Instructions eliminated: " + std::to_string(instructionsSaved));

       
        finalResult.push_back("; ================================");
    }
    
    return finalResult;
}





     void emitDataSection() {
        emit(".MODEL SMALL");
        emit(".STACK 100H");
        emit("");
        emit(".DATA");
        emit("    number DB \"00000$\"");
        
        for (const auto& var : globalVariables) {
            if (symbolTable && symbolTable->isArray(var)) {
                int arraySize = symbolTable->getArraySize(var);
                emit("    " + var + " DW " + std::to_string(arraySize) + " DUP(?)");
            } else {
                emit("    " + var + " DW ?");
            }
        }
        
        emit("");
        emit(".CODE");
        emit("");
        
        emit("new_line PROC");
        emit("    PUSH AX");
        emit("    PUSH DX");
        emit("    MOV AH, 2");
        emit("    MOV DL, 0DH");
        emit("    INT 21H");
        emit("    MOV AH, 2");
        emit("    MOV DL, 0AH");
        emit("    INT 21H");
        emit("    POP DX");
        emit("    POP AX");
        emit("    RET");
        emit("new_line ENDP");
        emit("");
        
        emit("print_output PROC");
        emit("    PUSH AX");
        emit("    PUSH BX");
        emit("    PUSH CX");
        emit("    PUSH DX");
        emit("    PUSH SI");
        emit("    LEA SI, number");
        emit("    MOV BX, 10");
        emit("    ADD SI, 4");
        emit("    CMP AX, 0");
        emit("    JNGE negate");
        emit("print:");
        emit("    XOR DX, DX");
        emit("    DIV BX");
        emit("    MOV [SI], DL");
        emit("    ADD [SI], '0'");
        emit("    DEC SI");
        emit("    CMP AX, 0");
        emit("    JNE print");
        emit("    INC SI");
        emit("    LEA DX, SI");
        emit("    MOV AH, 9");
        emit("    INT 21H");
        emit("    POP SI");
        emit("    POP DX");
        emit("    POP CX");
        emit("    POP BX");
        emit("    POP AX");
        emit("    RET");
        emit("negate:");
        emit("    PUSH AX");
        emit("    MOV AH, 2");
        emit("    MOV DL, '-'");
        emit("    INT 21H");
        emit("    POP AX");
        emit("    NEG AX");
        emit("    JMP print");
        emit("print_output ENDP");
        emit("");
    }


    struct VariableInfo 
    {
        std::string name;
        bool isArray;
        int arraySize;
    };

    struct OperatorContext
     {
        std::string op;
        std::string label1;
        std::string label2;
        std::string type;
    };

    std::stack<OperatorContext> opContextStack;

    bool localsInitialised = false;

void ensureLocalsReady()
{
        if (isInFunction && compoundDepth == 1 && !localsInitialised) 
        {
            if (currentOffset < 0) {
                emit("    ; Allocate locals");
                emit("    SUB SP, " + std::to_string(-currentOffset));
            }
            // no zero-initialization of each slot:
            localsInitialised = true;
        }
 }
int getVariableOffset(const std::string &varName) 
{
        if (variableOffsets.find(varName) == variableOffsets.end()) 
        {
            currentOffset -= 2;
            variableOffsets[varName] = currentOffset;
        }
        return variableOffsets[varName];
}
void emitVariableLoad(const std::string& varName) 
{
        bool hasLocalOffset = variableOffsets.find(varName) != variableOffsets.end();
        bool isGlobal = std::find(globalVariables.begin(), globalVariables.end(), varName) != globalVariables.end();
        
        if (isInFunction && hasLocalOffset) 
        
        {
            int offset = variableOffsets[varName];
            if (offset > 0) {
                emit("    MOV AX, [BP+" + std::to_string(offset) + "]");
            } else {
                emit("    MOV AX, [BP" + std::to_string(offset) + "]");
            }
        } else if (isGlobal) 
        {
            emit("    MOV AX, " + varName);
        } 
        else 
        {
            int offset = getVariableOffset(varName);
            std::string offsetStr = (offset >= 0) ? "+" + std::to_string(offset) : std::to_string(offset);
            emit("    MOV AX, [BP" + offsetStr + "]");
        }
}
void emitVariableStore(const std::string& varName) 
{
        bool hasLocalOffset = variableOffsets.find(varName) != variableOffsets.end();
        bool isGlobal = std::find(globalVariables.begin(), globalVariables.end(), varName) != globalVariables.end();
        
        if (isInFunction && hasLocalOffset) 
        {
            int offset = variableOffsets[varName];
            if (offset > 0) 
            {
                emit("    MOV [BP+" + std::to_string(offset) + "], AX");
            } 
            else 
            {
                emit("    MOV [BP" + std::to_string(offset) + "], AX");
            }
        } 
        else if (isGlobal) 
        {
            emit("    MOV " + varName + ", AX");
        } 
        else 
        {
            int offset = getVariableOffset(varName);
            std::string offsetStr = (offset >= 0) ? "+" + std::to_string(offset) : std::to_string(offset);
            emit("    MOV [BP" + offsetStr + "], AX");
        }
}

void emitArrayAccess(const std::string& varName, bool isStore = false) 
{
        emit("    ; Array access: " + varName + "[index]");
        emit("    MOV BX, AX");
        emit("    SHL BX, 1");
        
        if (!isInFunction || std::find(globalVariables.begin(), globalVariables.end(), varName) != globalVariables.end()) 
        {
            emit("    LEA SI, " + varName);
            emit("    ADD SI, BX");
        }
        else 
        {
            int offset = getVariableOffset(varName);
            emit("    LEA SI, [BP" + std::to_string(offset) + "]");
            emit("    SUB SI, BX");
        }
        
        if (!isStore) 
        {
            emit("    MOV AX, [SI]");
        }
 }

void pushOperatorContext(const std::string& op, const std::string& type) 
{
        OperatorContext ctx;
        ctx.op = op;
        ctx.type = type;
        ctx.label1 = generateLabel();
        ctx.label2 = generateLabel();
        opContextStack.push(ctx);
}
OperatorContext popOperatorContext() 
{
        OperatorContext ctx = opContextStack.top();
        opContextStack.pop();
        return ctx;
}
std::string generateLabel() 
{
        return "L" + std::to_string(labelCount++);
}

void emitCall(const std::string &fn, int count) 
{
          emit("    ; Function call: " + fn);
          emit("    CALL " + fn);
          if (count > 0)
         {
          emit("    ADD SP, " + std::to_string(count * 2));
         }
 }


}


start : {
           if (symbolTable == nullptr) 
        {
            symbolTable = new SymbolTable(7);
        }
         generatedCode.clear(); 

        }program
	    {
          
          writeIntoparserLogFile("Parsing completed successfully with " + std::to_string(syntaxErrorCount) + " syntax errors.");
        if (syntaxErrorCount == 0 && asmFile.is_open()) 
        {
            emit("");
            emit("END main");
            
            // Generate optimized code
            writeOptimizedCode();

        }
          isInFunction = false;

        if (symbolTable) 
        {
           delete symbolTable;
           symbolTable = nullptr;
        }
	    }
	;

program : program unit 
	| unit
	;
	
unit : var_declaration
     | func_declaration
     | func_definition
     ;
     
func_declaration : t=type_specifier id=ID LPAREN pl=parameter_list RPAREN SEMICOLON
  {
        std::string funcName = $id->getText();
        std::string returnType = $t.typeStr;
        
        if (symbolTable && symbolTable->isDeclared(funcName)) 
        {
            writeIntoErrorFile("Line# " + std::to_string($id->getLine()) + 
                             ": Function '" + funcName + "' multiple declaration");
            syntaxErrorCount++;
        } else if (symbolTable) 
        {
            FunctionInfo* funcInfo = new FunctionInfo(returnType);
            
            for (int i = 0; i < $pl.paramNames.size(); i++) 
            {
                funcInfo->addParameter($pl.paramTypes[i], $pl.paramNames[i]);
            }
            
            funcInfo->setIsDeclared(true);
            funcInfo->setDeclarationLine($id->getLine());
            
            symbolTable->InsertFunction(funcName, funcInfo);
            writeIntoparserLogFile("Function declared: " + funcName);
        }
    }
    | t=type_specifier id=ID LPAREN RPAREN SEMICOLON 
    {
        std::string funcName = $id->getText();
        std::string returnType = $t.typeStr;
        
        if (symbolTable && symbolTable->isDeclared(funcName)) 
        {
            writeIntoErrorFile("Line# " + std::to_string($id->getLine()) + 
                             ": Function '" + funcName + "' multiple declaration");
            syntaxErrorCount++;
        } 
        else if (symbolTable) 
        {
            FunctionInfo* funcInfo = new FunctionInfo(returnType);
            funcInfo->setIsDeclared(true);
            funcInfo->setDeclarationLine($id->getLine());
            
            symbolTable->InsertFunction(funcName, funcInfo);
            writeIntoparserLogFile("Function declared: " + funcName);
        }
    }
    ;
		 
func_definition : t=type_specifier id=ID LPAREN pl=parameter_list RPAREN {
        if (!dataSectionGenerated) 
        {
            emitDataSection();
            dataSectionGenerated = true;
        }
        
        std::string funcName = $id->getText();
        std::string returnType = $t.typeStr;
        
        currentFunctionName = funcName;
        currentFunctionReturnType = returnType;
        isInFunction = true;
        compoundDepth = 0;
        hasReturnStatement = false;
        
        variableOffsets.clear();
        currentOffset = 0;
        localsInitialised = false;
        
        emit(funcName + " PROC");
        if (funcName == "main")
       {
            emit("    MOV AX, @DATA");
            emit("    MOV DS, AX");
        }
        
        emit("    PUSH BP");
        emit("    MOV BP, SP");
        
        if (symbolTable) 
        {
            if (!symbolTable->isDeclared(funcName)) 
            {
                FunctionInfo* funcInfo = new FunctionInfo(returnType);
                
                for (int i = 0; i < $pl.paramNames.size(); i++) {
                    funcInfo->addParameter($pl.paramTypes[i], $pl.paramNames[i]);
                }
                
                funcInfo->setIsDefined(true);
                funcInfo->setDefinitionLine($id->getLine());
                symbolTable->InsertFunction(funcName, funcInfo);
            }
        }
        
        if (symbolTable) 
        {
            symbolTable->EnterScope(7, symbolTable->getCurrentScopeId());
            
            for (int i = 0; i < $pl.paramNames.size(); i++) 
            {
                symbolTable->InsertVariable($pl.paramNames[i], $pl.paramTypes[i], false, 0);
                variableOffsets[$pl.paramNames[i]] = 4 + (($pl.paramNames.size() - 1 - i) * 2);
            }
        }
    } compound_statement
	| t=type_specifier id=ID LPAREN RPAREN
        {
             if (!dataSectionGenerated) 
            {
                 emitDataSection();
                 dataSectionGenerated = true;
            }
            std::string funcName = $id->getText();
            std::string returnType = $t.typeStr;

            currentFunctionName = funcName;
            currentFunctionReturnType = returnType;
            isInFunction = true;
            compoundDepth = 0;
            hasReturnStatement = false;
            variableOffsets.clear();
            currentOffset = 0;
            localsInitialised = false;
            emit(funcName + " PROC");
            if (funcName == "main") 
            {
              emit("    MOV AX, @DATA");
              emit("    MOV DS, AX");
            }

             emit("    PUSH BP");
             emit("    MOV BP, SP");

            if (symbolTable) 
            {
            if (!symbolTable->isDeclared(funcName)) 
            {
                FunctionInfo* funcInfo = new FunctionInfo(returnType);
                funcInfo->setIsDefined(true);
                funcInfo->setDefinitionLine($id->getLine());
                symbolTable->InsertFunction(funcName, funcInfo);
            }
        }
        
        if (symbolTable) 
        {
            symbolTable->EnterScope(7, symbolTable->getCurrentScopeId());
        }
        } compound_statement
 		;				


parameter_list returns [std::vector<std::string> paramNames, std::vector<std::string> paramTypes]
    : pl=parameter_list COMMA t=type_specifier id=ID 
    {
        $paramNames = $pl.paramNames;
        $paramTypes = $pl.paramTypes;
        $paramNames.push_back($id->getText());
        $paramTypes.push_back($t.typeStr);
    }
    | pl=parameter_list COMMA t=type_specifier 
    {
        $paramNames = $pl.paramNames;
        $paramTypes = $pl.paramTypes;
        $paramTypes.push_back($t.typeStr);
    }
    | t=type_specifier id=ID 
    {
        $paramNames.push_back($id->getText());
        $paramTypes.push_back($t.typeStr);
    }
    | t=type_specifier 
    {
        $paramTypes.push_back($t.typeStr);
    }
    ;


 		
compound_statement : LCURL{
                    compoundDepth++;

}statements RCURL{
            bool isMainCompoundEnd = (isInFunction && compoundDepth == 1);
            if (isMainCompoundEnd)
           {
            if (!hasReturnStatement) 
            {
                if (currentFunctionName == "main") 
                {
                    emit("    ; Function epilogue");
                    emit("    MOV SP, BP");
                    emit("    POP BP");
                    emit("    MOV AH, 4CH");
                    emit("    INT 21H");
                } else 
                {
                    emit("    ; Function epilogue");
                    emit("    MOV SP, BP");
                    emit("    POP BP");
                    emit("    RET");
                }
            }
            
            emit(currentFunctionName + " ENDP");
            
            if (symbolTable) 
            {
                symbolTable->ExitScope();
            }
        }
        
        compoundDepth--;
}
 	| LCURL {
        compoundDepth++;
    } RCURL {
        bool isMainCompoundEmptyEnd = (isInFunction && compoundDepth == 1);
        
        if (isMainCompoundEmptyEnd) 
        {
            if (currentFunctionName == "main") 
            {
                emit("    ; Function epilogue");
                emit("    MOV SP, BP");
                emit("    POP BP");
                emit("    MOV AH, 4CH");
                emit("    INT 21H");
            } 
            else 
            {
                emit("    ; Function epilogue");
                emit("    MOV SP, BP");
                emit("    POP BP");
                emit("    RET");
            }
            
            emit(currentFunctionName + " ENDP");
            
            if (symbolTable) 
            {
                symbolTable->ExitScope();
            }
        }
        
        compoundDepth--;
    }
    ;
 		    
var_declaration : t=type_specifier dl=declaration_list SEMICOLON 
{
        std::string typeStr = $t.typeStr;

        for (const auto& varInfo : $dl.variables) 
        {
            if (symbolTable && symbolTable->isDeclaredInCurrentScope(varInfo.name)) 
            {
                writeIntoErrorFile("Line# " + std::to_string($SEMICOLON->getLine()) + 
                                 ": Variable '" + varInfo.name + "' multiple declaration");
                syntaxErrorCount++;
                continue;
            }
            
            if (!isInFunction) 
            {
                globalVariables.push_back(varInfo.name);
                if (symbolTable) 
                {
                    symbolTable->InsertVariable(varInfo.name, typeStr, varInfo.isArray, varInfo.arraySize);
                }
            } else 
            {
                if (symbolTable) 
                {
                    symbolTable->InsertVariable(varInfo.name, typeStr, varInfo.isArray, varInfo.arraySize);
                }
                
                if (varInfo.isArray) 
                {
                    currentOffset -= 2;
                    variableOffsets[varInfo.name] = currentOffset;
                    currentOffset -= (varInfo.arraySize - 1) * 2;
                } 
                else 
                {
                    currentOffset -= 2;
                    variableOffsets[varInfo.name] = currentOffset;
                }
            }
        }
    }
    ;
declaration_list_err returns [std::string error_name]: {
        $error_name = "Error in declaration list";
    };

 		 
type_specifier returns [std::string name_line, std::string typeStr]    
    : INT {
        $name_line = "type: INT at line" + std::to_string($INT->getLine());
        $typeStr = "INT";
    }
    | FLOAT {
        $name_line = "type: FLOAT at line" + std::to_string($FLOAT->getLine());
        $typeStr = "FLOAT";
    }
    | VOID {
        $name_line = "type: VOID at line" + std::to_string($VOID->getLine());
        $typeStr = "VOID";
    }
    ;
 		
declaration_list returns [std::vector<VariableInfo> variables]
    : dl=declaration_list COMMA id=ID {
        $variables = $dl.variables;
        $variables.push_back({$id->getText(), false, 0});
    }
    | dl=declaration_list COMMA id=ID LTHIRD size=CONST_INT RTHIRD {
        $variables = $dl.variables;
        $variables.push_back({$id->getText(), true, std::stoi($size->getText())});
    }
    | id=ID {
        $variables.push_back({$id->getText(), false, 0});
    }
    | id=ID LTHIRD size=CONST_INT RTHIRD {
        $variables.push_back({$id->getText(), true, std::stoi($size->getText())});
    }
    ;

 		  
statements : statement
	   | statements statement
	   ;
	   
statement : var_declaration
	  | expression_statement
	  | compound_statement
	  | FOR LPAREN init=expression_statement{
    
    ensureLocalsReady();

    std::string startLbl = generateLabel();

    std::string endLbl   = generateLabel();

    labelStack.push(startLbl);

    labelStack.push(endLbl);

    emit("    ; FOR loop transformed to WHILE");

    emit(startLbl + ":");
  }
    cond=expression_statement        
  {
  
    emit("    CMP AX, 0");
    emit("    JE " + labelStack.top());
  }
    id=ID INCOP RPAREN               
    stmt=statement                  
  {
    
    std::string varName = $id->getText();

    emit("    ; Post-increment: " + varName + "++");

    int offset = getVariableOffset(varName);

    std::string ofs = (offset >= 0 ? "+" : "") + std::to_string(offset);

    emit("    MOV AX, [BP" + ofs + "]");

    emit("    INC WORD PTR [BP" + ofs + "]");

   
    std::string endL   = labelStack.top(); labelStack.pop();

    std::string startL = labelStack.top(); labelStack.pop();

    emit("    JMP " + startL);

    emit(endL + ":");
  }
    | IF LPAREN expr=expression RPAREN {

        ensureLocalsReady();

        std::string ifEndLabel = generateLabel();

        labelStack.push(ifEndLabel);
        
        emit("    ; If statement");

        emit("    CMP AX, 0");

        emit("    JE " + ifEndLabel);
    } stmt=statement {

        std::string ifEndLbl = labelStack.top(); labelStack.pop();

        emit(ifEndLbl + ":");
    }
    | IF LPAREN expr=expression RPAREN {

        ensureLocalsReady();

        std::string elseLabel = generateLabel();

        std::string endLabel = generateLabel();

        labelStack.push(endLabel);

        labelStack.push(elseLabel);
        
        emit("    ; If-else statement");

        emit("    CMP AX, 0");

        emit("    JE " + elseLabel);

    } stmt1=statement ELSE {
        std::string elseLbl = labelStack.top(); labelStack.pop();

        std::string endLbl = labelStack.top();
        
        emit("    JMP " + endLbl);
        emit(elseLbl + ":");
    } stmt2=statement {
        std::string finalEndLbl = labelStack.top(); labelStack.pop();

        emit(finalEndLbl + ":");
    }
    | WHILE LPAREN
  {
    ensureLocalsReady();
  
    std::string lblStart = generateLabel();

    std::string lblEnd   = generateLabel();

   
    labelStack.push(lblStart);

    labelStack.push(lblEnd);

    emit("    ; While loop");

    emit(lblStart + ":");
  }
  expr=expression RPAREN
  {
   
    emit("    CMP AX, 0");

    emit("    JE " + labelStack.top());
  }
  stmt=statement
  {
   
    std::string lblEnd2   = labelStack.top(); labelStack.pop();

    std::string lblStart2 = labelStack.top(); labelStack.pop();

  
    emit("    JMP " + lblStart2);

    emit(lblEnd2 + ":");
  }
	| PRINTLN LPAREN id=ID RPAREN SEMICOLON 
      {
        ensureLocalsReady();

        std::string varName = $id->getText();
        
        bool isGlobal = std::find(globalVariables.begin(), globalVariables.end(), varName) != globalVariables.end();

        bool isDeclaredInSymTable = symbolTable && symbolTable->isDeclared(varName);

        bool hasLocalOffset = variableOffsets.find(varName) != variableOffsets.end();
        
        if (!isDeclaredInSymTable && !isGlobal && !hasLocalOffset) 
        {
            writeIntoErrorFile("Line# " + std::to_string($id->getLine()) + 
                             ": Undeclared variable '" + varName + "'");
            syntaxErrorCount++;
            emit("    ; ERROR: Undeclared variable " + varName);
        } 
        else if (symbolTable && symbolTable->isArray(varName))
       {
            writeIntoErrorFile("Line# " + std::to_string($id->getLine()) + 
                             ": Cannot print array without index");
            syntaxErrorCount++;
            emit("    ; ERROR: Cannot print array without index");
        } 
        else
       {
            emit("    ; println(" + varName + ")");
            emitVariableLoad(varName);
            emit("    CALL print_output");
            emit("    CALL new_line");
        }
    }
    | RETURN expr=expression SEMICOLON 
      {
        ensureLocalsReady();
       
        emit("    ; Return statement");
        
        if (currentFunctionName == "main") 
        {
            emit("    MOV SP, BP");
            emit("    POP BP");
            emit("    MOV AH, 4CH");
            emit("    INT 21H");
        } else {
            emit("    MOV SP, BP");
            emit("    POP BP");
            emit("    RET");
        }
        hasReturnStatement = true;
    }
	  ;
  
	  
expression_statement 	: SEMICOLON			
			| expression SEMICOLON 
			;
	  
variable returns [std::string name, bool isArrayAccess]
    : id=ID 
    {
        ensureLocalsReady();

        $name = $id->getText();

        $isArrayAccess = false;
        
        bool hasLocalOffset = variableOffsets.find($name) != variableOffsets.end();

        bool isDeclaredInSymTable = symbolTable && symbolTable->isDeclared($name);

        bool isGlobal = std::find(globalVariables.begin(), globalVariables.end(), $name) != globalVariables.end();
        
        if (!isDeclaredInSymTable && !isGlobal && !hasLocalOffset) 
        {
            writeIntoErrorFile("Line# " + std::to_string($id->getLine()) + 
                             ": Undeclared variable '" + $name + "'");
            syntaxErrorCount++;
            emit("    ; ERROR: Undeclared variable " + $name);
        } 
        else 
        {
            emitVariableLoad($name);
        }
    }	
	| id=ID LTHIRD expr=expression RTHIRD 
    {
        ensureLocalsReady();

        $name = $id->getText();

        $isArrayAccess = true;
        
        if (!symbolTable || !symbolTable->isDeclared($name))
       {
            writeIntoErrorFile("Line# " + std::to_string($id->getLine()) + 
                             ": Undeclared array '" + $name + "'");
            syntaxErrorCount++;
            emit("    ; ERROR: Undeclared array " + $name);
        } 
        else if (!symbolTable->isArray($name)) 
        {
            writeIntoErrorFile("Line# " + std::to_string($id->getLine()) + 
                             ": '" + $name + "' is not an array");
            syntaxErrorCount++;
            emit("    ; ERROR: Not an array");
        } 
        else
        {
            emitArrayAccess($name, false);
        }
    }
    ;
lhs returns [std::string name, bool isArrayAccess, std::string indexValue]
    : id=ID 
    {
        $name = $id->getText();
        $isArrayAccess = false;
        $indexValue = "";
    }
    | id=ID LTHIRD idx=expression RTHIRD 
    {
        $name = $id->getText();
        $isArrayAccess = true;
        $indexValue = $idx.ctx->getText();
    }
    ;	 
 expression
    : logic_expression
    | target=lhs ASSIGNOP rhs=expression 
    {
        std::string varName = $target.name;
        bool isArr = $target.isArrayAccess;
        
        if (isArr) 
        {
            emit("    ; Assignment: " + varName + " = expression");
            emit("    PUSH AX");
            emit("    ; Array access: " + varName + "[index]");
            
            if ($target.indexValue == "0") 
            {
                emit("    MOV AX, 0");
            } 
            else if ($target.indexValue == "1") 
            {
                emit("    MOV AX, 1");
            } 
            else 
            {
                emitVariableLoad($target.indexValue);
            }
            
            emit("    MOV BX, AX");
            emit("    SHL BX, 1");
            
            if (!isInFunction || std::find(globalVariables.begin(), globalVariables.end(), varName) != globalVariables.end()) 
            {
                emit("    LEA SI, " + varName);
                emit("    ADD SI, BX");
            } 
            else 
            {
                int offset = getVariableOffset(varName);
                emit("    LEA SI, [BP" + std::to_string(offset) + "]");
                emit("    SUB SI, BX");
            }
            
            emit("    POP AX");
            emit("    MOV [SI], AX");
        }
         else
        {
            emit("    ; Assignment: " + varName + " = expression");
            emitVariableStore(varName);
        }
    }
    ;
			
logic_expression : rel_expression
    | rel_expression op=LOGICOP 
    {
        pushOperatorContext($op->getText(), "LOGIC");
        OperatorContext logicCtx = opContextStack.top();
        
        emit("    ; Logical " + logicCtx.op + " operation");
        emit("    PUSH AX");
        
        if (logicCtx.op == "&&") 
        {
            emit("    CMP AX, 0");
            emit("    JE " + logicCtx.label1);
        } 
        else if (logicCtx.op == "||") 
        {
            emit("    CMP AX, 0");
            emit("    JNE " + logicCtx.label1);
        }
    } rel_expression 
    {
        OperatorContext finalLogicCtx = popOperatorContext();
        
        emit("    MOV BX, AX");
        emit("    POP AX");
        
        if (finalLogicCtx.op == "&&") 
        {
            emit("    CMP BX, 0");
            emit("    JE " + finalLogicCtx.label1);
            emit("    MOV AX, 1");
            emit("    JMP " + finalLogicCtx.label2);
            emit(finalLogicCtx.label1 + ":");
            emit("    MOV AX, 0");
            emit(finalLogicCtx.label2 + ":");
        } 
        else if (finalLogicCtx.op == "||") 
        {
            emit("    CMP BX, 0");
            emit("    JNE " + finalLogicCtx.label1);
            emit("    MOV AX, 0");
            emit("    JMP " + finalLogicCtx.label2);
            emit(finalLogicCtx.label1 + ":");
            emit("    MOV AX, 1");
            emit(finalLogicCtx.label2 + ":");
        }
    }
    ;
			
rel_expression : simple_expression
    | simple_expression op=RELOP 
    {
        pushOperatorContext($op->getText(), "REL");
        OperatorContext relCtx = opContextStack.top();
        
        emit("    ; Relational operation: " + relCtx.op);
        emit("    PUSH AX");
    } simple_expression 
    {
        OperatorContext finalRelCtx = popOperatorContext();
        
        emit("    MOV BX, AX");
        emit("    POP AX");
        emit("    CMP AX, BX");
        
        if (finalRelCtx.op == "<") 
        {
            emit("    JL " + finalRelCtx.label1);
        } 
        else if (finalRelCtx.op == "<=") 
        {
            emit("    JLE " + finalRelCtx.label1);
        } 
        else if (finalRelCtx.op == ">") 
        {
            emit("    JG " + finalRelCtx.label1);
        }
         else if (finalRelCtx.op == ">=") 
        {
            emit("    JGE " + finalRelCtx.label1);
        } 
        else if (finalRelCtx.op == "==") 
        {
            emit("    JE " + finalRelCtx.label1);
        } 
        else if (finalRelCtx.op == "!=") 
        {
            emit("    JNE " + finalRelCtx.label1);
        }
        
        emit("    MOV AX, 0");
        emit("    JMP " + finalRelCtx.label2);
        emit(finalRelCtx.label1 + ":");
        emit("    MOV AX, 1");
        emit(finalRelCtx.label2 + ":");
    }
    ;
				
simple_expression
  : term
    ( op=ADDOP 
    {
        pushOperatorContext($op->getText(), "ARITH");
        emit("    ; Arithmetic operation: " + $op->getText());
        emit("    PUSH AX");
      }
      term 
      {
        OperatorContext ctx = popOperatorContext();
        emit("    MOV BX, AX");
        emit("    POP AX");
        if (ctx.op == "+") 
        {
            emit("    ADD AX, BX");
        } 
        else if (ctx.op == "-")
        {
            emit("    SUB AX, BX");
        } 
        // else if (ctx.op == "|") 
        // {
        //     emit("    OR AX, BX");
        // } 
        // else if (ctx.op == "&") 
        // {
        //     emit("    AND AX, BX");
        // } 
        // else if (ctx.op == "^") 
        // {
        //     emit("    XOR AX, BX");
        // }
       
      }
    )*
  ;
					
term
  : unary_expression
    ( op=MULOP {
        pushOperatorContext($op->getText(), "MUL");
        emit("    ; Multiplication/Division operation: " + $op->getText());
        emit("    PUSH AX");
      }
      unary_expression 
      {
        OperatorContext ctx = popOperatorContext();
        emit("    MOV BX, AX");
        emit("    POP AX");
        if      (ctx.op == "*") 
        {
          emit("    MUL BX");
        } 
        else if (ctx.op == "/")
        {
          emit("    CWD");
          emit("    IDIV BX");
        } 
        else /* % */ 
        {
          emit("    CWD");
          emit("    IDIV BX");
          emit("    MOV AX, DX");
        }
      }
    )*
  ;


unary_expression : op=ADDOP 
    {
        contextStack.push($op->getText());

        emit("    ; Unary operation: " + $op->getText());
    } unary_expression 
    {
        std::string unaryOp = contextStack.top(); contextStack.pop();

        if (unaryOp == "-") 
        {
            emit("    NEG AX");
        }
    }
    | op=NOT
    {
        std::string label1 = generateLabel();

        std::string label2 = generateLabel();

        labelStack.push(label2);

        labelStack.push(label1);
        
        emit("    ; Logical NOT operation");
    } unary_expression 
    {
        std::string trueLbl = labelStack.top(); labelStack.pop();

        std::string endLbl = labelStack.top(); labelStack.pop();
        
        emit("    CMP AX, 0");

        emit("    JE " + trueLbl);

        emit("    MOV AX, 0");

        emit("    JMP " + endLbl);

        emit(trueLbl + ":");

        emit("    MOV AX, 1");

        emit(endLbl + ":");
    }
    | factor
    ;
	
factor	: id=ID LPAREN args=arguments RPAREN 
    {
      ensureLocalsReady();
      std::string fn = $id->getText();
      if (!symbolTable || !symbolTable->isFunction(fn)) 
      {
        writeIntoErrorFile("Line# " +
            std::to_string($id->getLine()) +
            ": Undeclared function '" + fn + "'");
        syntaxErrorCount++;
        emit("    ; ERROR: Undeclared function");
      } 
      else 
      {
        emitCall(fn, $args.argCount);
      }
    }
    | variable 
	
	| val=CONST_INT 
    {
        ensureLocalsReady();
        emit("    MOV AX, " + $val->getText());
    }
	| CONST_FLOAT
    | LPAREN expression RPAREN
	| id=ID INCOP 
    {
        ensureLocalsReady();
        std::string varName = $id->getText();
        
        emit("    ; Post-increment: " + varName + "++");
        
        bool hasLocalOffset = variableOffsets.find(varName) != variableOffsets.end();

        bool isGlobal = std::find(globalVariables.begin(), globalVariables.end(), varName) != globalVariables.end();
        
        if (isInFunction && hasLocalOffset)
        {
            int offset = variableOffsets[varName];
            if (offset > 0)
            {
                emit("    MOV AX, [BP+" + std::to_string(offset) + "]");
                emit("    INC WORD PTR [BP+" + std::to_string(offset) + "]");
            }
             else 
            {
                emit("    MOV AX, [BP" + std::to_string(offset) + "]");
                emit("    INC WORD PTR [BP" + std::to_string(offset) + "]");
            }
        } 
        else if (isGlobal) 
        {
            emit("    MOV AX, " + varName);
            emit("    INC WORD PTR " + varName);
        }
    }
	| id=ID LTHIRD idx=expression RTHIRD INCOP 
    {
        ensureLocalsReady();
        std::string varName = $id->getText();
        std::string indexText = $idx.ctx->getText();
        
        emit("    ; Post-increment: " + varName + "++");
        emit("    ; Array access: " + varName + "[index]");
        
        if (indexText == "0") 
        {
            emit("    MOV AX, 0");
        } 
        else if (indexText == "1") 
        {
            emit("    MOV AX, 1");
        } 
        else 
        {
            emitVariableLoad(indexText);
        }
        
        emit("    MOV BX, AX");
        emit("    SHL BX, 1");
        
        if (!isInFunction || std::find(globalVariables.begin(), globalVariables.end(), varName) != globalVariables.end()) 
        {
            emit("    LEA SI, " + varName);
            emit("    ADD SI, BX");
        } 
        else 
        {
            int offset = getVariableOffset(varName);
            emit("    LEA SI, [BP" + std::to_string(offset) + "]");
            emit("    SUB SI, BX");
        }
        
        emit("    MOV AX, [SI]");
        emit("    INC WORD PTR [SI]");
    }
    | id=ID DECOP 
    {
        ensureLocalsReady();
        std::string varName = $id->getText();
        
        emit("    ; Post-decrement: " + varName + "--");
        
        bool hasLocalOffset = variableOffsets.find(varName) != variableOffsets.end();

        bool isGlobal = std::find(globalVariables.begin(), globalVariables.end(), varName) != globalVariables.end();
        
        if (isInFunction && hasLocalOffset) 
        {
            int offset = variableOffsets[varName];
            if (offset > 0) 
            {
                emit("    MOV AX, [BP+" + std::to_string(offset) + "]");
                emit("    DEC WORD PTR [BP+" + std::to_string(offset) + "]");
            } 
            else 
            {
                emit("    MOV AX, [BP" + std::to_string(offset) + "]");
                emit("    DEC WORD PTR [BP" + std::to_string(offset) + "]");
            }
        } 
        else if (isGlobal) 
        {
            emit("    MOV AX, " + varName);
            emit("    DEC WORD PTR " + varName);
        }
    }
	;
	
arguments
    returns [int argCount]
    : {
        $argCount = 0;
      }
      first=logic_expression 
      {
        emit("    PUSH AX");
        $argCount = 1;
      }
      ( COMMA next=logic_expression 
      {
          emit("    PUSH AX");
          $argCount++;
        }
      )*
    | { $argCount = 0; }
    ;