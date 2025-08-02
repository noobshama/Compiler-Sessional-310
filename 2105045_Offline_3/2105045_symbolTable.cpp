#ifndef SYMBOLTABLE_CPP_GUARD
#define SYMBOLTABLE_CPP_GUARD
#include <bits/stdc++.h>
#include "2105045_symbolInfo.cpp"
//#include "2105045_hashFunction.cpp"
#include "2105045_scopeTable.cpp"

using namespace std;

class SymbolTable
{
    private :

    ScopeTable *currentScope;

    //int currentScopeId;

    int totalCollisions = 0; 

    int totalScopeTables = 0;

    public:

    SymbolTable( unsigned int size)

    {

        currentScope = nullptr;

        //currentScopeId = 0;

        EnterScope(size, "0");


    }

    ~SymbolTable()
    {
        exitAllScope();
    }

    void EnterScope( unsigned int size, string parentscopeId)

    {

        //currentScopeId++;

        ScopeTable *newScope = new ScopeTable(size,  currentScope, parentscopeId);


        newScope->setParentScope(currentScope);

        currentScope = newScope;

        totalScopeTables++;
        currentScope->incrementScopeId();

        //cout << "\tScopeTable# " << currentScope->getId() << " created" << endl;

    }
    void printCollisionStats()
    {
        cout << "Total Scope Tables: " << totalScopeTables << endl;

        cout << "Total Collisions: " << totalCollisions << endl;

    }
    int getTotalCollisionCount()
    {

        return totalCollisions;


    }
    int getScopeCount() 
    {


        return totalScopeTables;


    }

    void ExitScope()


    {
        if (currentScope != nullptr && currentScope->getParentScope() != nullptr)


        {
            ScopeTable *temp = currentScope;


           // cout << "\tScopeTable# " << currentScope->getId() << " removed" << endl;


            currentScope = currentScope->getParentScope();


            delete temp;
            currentScope->incrementScopeId();

        }

        else
        {
           // cout << "\tScopeTable# 1 cannot be deleted" << endl;
        }
        totalCollisions += currentScope->getCollisionCount(); 
    }

    void exitAllScope()
    {
        if (currentScope == nullptr)
        {
            return;
        }
        while (currentScope->getParentScope() != nullptr)

        {

            ScopeTable *temp = currentScope;

            //cout << "\tScopeTable# " << currentScope->getId() << " removed" << endl;

            currentScope = currentScope->getParentScope();

            delete temp;

        }
        delete currentScope;

        //cout << "\tScopeTable# 1 removed" << endl;
    }

    bool Insert( const string& name, const string& type)
    {
        bool result = currentScope->Insert(name, type);
        
        return result;
    }

    bool InsertVariable(const string& name, const string& dataType, bool isArray = false, int arraySize = -1)
    {
        return currentScope->InsertVariable(name, dataType, isArray, arraySize);
    }
    bool InsertFunction(const string& name, FunctionInfo* funcInfo)
    {
        return currentScope->InsertFunction(name, funcInfo);
    }

    bool Remove(const string &name)

    {

        return currentScope->Delete(name);


    }

    SymbolInfo *LookUp(const string &name) 
    {

        ScopeTable *scope = currentScope;

      
        while (scope != nullptr)

        {

            SymbolInfo *result = scope->LookUp(name);

           
            
            if (result != nullptr)


            {

                return result;


            }


            scope = scope->getParentScope();


        }


        return nullptr;


    }
    SymbolInfo* LookUpInCurrentScope( string &name)


{
    
    return currentScope->LookUp(name);


}


void printCurrentScope(std::ofstream &fout) 
{
    currentScope->Print(fout);
}

void printAllScopes(std::ofstream &fout) 
{
    ScopeTable *scope = currentScope;
    while (scope != nullptr) {
        scope->Print(fout);
        scope = scope->getParentScope();
    }
    fout << std::endl;
}
    string getCurrentScopeId() 

    {

        return currentScope->getIdNum();


    }

    ScopeTable *getCurrentScope() 
    {

        return currentScope;


    }
    bool isDeclaredInCurrentScope(const string &name)
    {
        return currentScope->LookUp(name) != nullptr;
    }
    
    bool isDeclared(const string &name)
    {
        return LookUp(name) != nullptr;
    }
    
    bool isFunction(const string &name)
    {
        SymbolInfo* symbol = LookUp(name);
        return symbol != nullptr && symbol->getIsFunction();
    }
    
    bool isArray(const string &name)
    {
        SymbolInfo* symbol = LookUp(name);
        return symbol != nullptr && symbol->getIsArray();
    }
    
    bool isVariable(const string &name)
    {
        SymbolInfo* symbol = LookUp(name);
        return symbol != nullptr && !symbol->getIsFunction();
    }
    
    string getDataType(const string &name)
    {
        SymbolInfo* symbol = LookUp(name);
        if (symbol != nullptr) {
            return symbol->getDataType();
        }
        return "";
    }
    
    FunctionInfo* getFunctionInfo(const string &name)
    {
        SymbolInfo* symbol = LookUp(name);
        if (symbol != nullptr && symbol->getIsFunction()) {
            return symbol->getFunctionInfo();
        }
        return nullptr;
    }
    
    // Type checking helpers
    bool isIntType(const string &name)
    {
        SymbolInfo* symbol = LookUp(name);
        return symbol != nullptr && symbol->isIntType();
    }
    
    bool isFloatType(const string &name)
    {
        SymbolInfo* symbol = LookUp(name);
        return symbol != nullptr && symbol->isFloatType();
    }
    
    bool isVoidType(const string &name)
    {
        SymbolInfo* symbol = LookUp(name);
        return symbol != nullptr && symbol->isVoidType();
    }
    
    // Function-specific operations
    bool declareFunctionIfNotExists(const string &name, const string &returnType, const vector<Parameter> &params, int line)
    {
        SymbolInfo* existing = LookUp(name);
        if (existing != nullptr) {
            if (!existing->getIsFunction()) {
                return false; // Variable with same name exists
            }
            
            FunctionInfo* existingFunc = existing->getFunctionInfo();
            FunctionInfo tempFunc(returnType);
            for (const auto& param : params) {
                tempFunc.addParameter(param.type, param.name);
            }
            
            if (!existingFunc->matchesSignature(tempFunc)) {
                return false; // Signature mismatch
            }
            
            if (!existingFunc->getIsDeclared()) {
                existingFunc->setIsDeclared(true);
                existingFunc->setDeclarationLine(line);
            }
            return true;
        } else {
            // New function declaration
            FunctionInfo* funcInfo = new FunctionInfo(returnType);
            for (const auto& param : params) {
                funcInfo->addParameter(param.type, param.name);
            }
            funcInfo->setIsDeclared(true);
            funcInfo->setDeclarationLine(line);
            
            return InsertFunction(name, funcInfo);
        }
    }
    
    bool defineFunctionIfNotDefined(const string &name, const string &returnType, const vector<Parameter> &params, int line)
    {
        SymbolInfo* existing = LookUp(name);
        if (existing != nullptr) {
            if (!existing->getIsFunction()) {
                return false; // Variable with same name exists
            }
            
            FunctionInfo* existingFunc = existing->getFunctionInfo();
            FunctionInfo tempFunc(returnType);
            for (const auto& param : params) {
                tempFunc.addParameter(param.type, param.name);
            }
            
            if (!existingFunc->matchesSignature(tempFunc)) {
                return false; // Signature mismatch with declaration
            }
            
            if (existingFunc->getIsDefined()) {
                return false; // Already defined
            }
            
            existingFunc->setIsDefined(true);
            existingFunc->setDefinitionLine(line);
            return true;
        } else {
            // New function definition
            FunctionInfo* funcInfo = new FunctionInfo(returnType);
            for (const auto& param : params) {
                funcInfo->addParameter(param.type, param.name);
            }
            funcInfo->setIsDefined(true);
            funcInfo->setDefinitionLine(line);
            
            return InsertFunction(name, funcInfo);
        }
    }
    
    // Validate function call
    pair<bool, string> validateFunctionCall(const string &name, const vector<string> &argTypes, int line)
    {
        SymbolInfo* symbol = LookUp(name);
        if (symbol == nullptr) {
            return make_pair(false, "Undefined function " + name);
        }
        
        if (!symbol->getIsFunction()) {
            return make_pair(false, name + " is not a function");
        }
        
        FunctionInfo* funcInfo = symbol->getFunctionInfo();
        if (funcInfo->getParameterCount() != argTypes.size()) {
            return make_pair(false, "Total number of arguments mismatch with declaration in function " + name);
        }
        
        for (int i = 0; i < argTypes.size(); i++) {
            string expectedType = funcInfo->getParameterType(i);
            string actualType = argTypes[i];
            
            // Type matching logic - you can enhance this based on your needs
            if (expectedType != actualType) {
                // Allow int to float conversion implicitly if needed
                if (!(expectedType == "FLOAT" && actualType == "INT")) {
                    return make_pair(false, to_string(i+1) + "th argument mismatch in function " + name);
                }
            }
        }
        
        return make_pair(true, "");
    }
    

};
#endif