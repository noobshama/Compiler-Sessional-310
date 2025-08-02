#ifndef SYMBOLINFO_CPP_GUARD
#define SYMBOLINFO_CPP_GUARD
#include <bits/stdc++.h>
#include "2105045_functionInfo.cpp"

using namespace std;

class SymbolInfo
{
     private :

     string name;

     string type;


     int scopeTableIndex;

     unsigned int hashIndex;

     int linkedListIndex;

     SymbolInfo *next;


     bool isArray;
     int arraySize;
     FunctionInfo* funcInfo;
     string dataType;
     bool isFunction;
     
    public :


    SymbolInfo(string name , string type, int scopeTableIndex, unsigned int hashIndex , int linkedListIndex )
    {
        this->name = name;


        this->type = type;

        this->scopeTableIndex = scopeTableIndex;


        this->hashIndex = hashIndex;


        this->linkedListIndex = linkedListIndex;


        next = nullptr;

        isArray = false;
        arraySize = -1;
        funcInfo = nullptr;
        dataType = "";
        isFunction = false;
    }

    ~SymbolInfo() 
    {
        if (funcInfo != nullptr)
      {
            delete funcInfo;
        }
    }

    string getName()

    {
        return name;
    }

    string getType()
    {
        return type;
    }

    int getScopeTableIndex()
    {
        return scopeTableIndex;
    }

    unsigned int getHashIndex()
    {
        return hashIndex;
    }

    int getLinkedListIndex()
    {
        return linkedListIndex;
    }

    SymbolInfo *getNext()
    {
        return next;
    }

    void setName(string name)
    {
        this->name = name;
    }

    void setType(string type)
    {
        this->type = type;
    }

    void setScopeTableIndex(int scopeTableIndex)
    {
        this->scopeTableIndex = scopeTableIndex;
    }

    void setHashIndex(unsigned int hashIndex)
    {
        this->hashIndex = hashIndex;
    }

    void setLinkedListIndex(int linkedListIndex)
    {
        this->linkedListIndex = linkedListIndex;
    }

    void setNext(SymbolInfo *next)
    {
        this->next = next;
    }

    bool getIsArray() const 
    {  
        return isArray; 
    }

    int getArraySize() const 
    {  
        return arraySize;
   }
   FunctionInfo* getFunctionInfo() const
    { 
        return funcInfo;
     }

     string getDataType() const 
     { 
        return dataType; 
    }
    bool getIsFunction() const 
    { 
        return isFunction; 
    }
    void setIsArray(bool array)
     { 
        isArray = array; 
    }
    void setArraySize(int size) 
    {
         arraySize = size;
         }
    void setDataType(string dtype) 
    { 
        dataType = dtype;
     }
    void setIsFunction(bool func) 
    { 
        isFunction = func; 
    }
    void setFunctionInfo(FunctionInfo* info) 
    {
        if (funcInfo != nullptr) {
            delete funcInfo;
        }
        funcInfo = info;
        isFunction = true;
    }
    
   
    bool isVar() const 
    {
        return !isFunction && !isArray;
    }
    
    bool isArrayVar() const 
    {
        return isArray && !isFunction;
    }
    
    bool isFunctionSymbol() const 
    {
        return isFunction;
    }
    
  
    bool isIntType() const 
    {
        return dataType == "INT" || dataType == "int";
    }
    
    bool isFloatType() const 
    {
        return dataType == "FLOAT" || dataType == "float";
    }
    
    bool isVoidType() const 
    {
        return dataType == "VOID" || dataType == "void";
    }
    

    string getCompleteType() const 
    {
        if (isFunction && funcInfo != nullptr) 
        {	
            return "FUNCTION " + funcInfo->getFunctionSignature();
        } 
        else if (isArray)
       {
            return dataType + "[" + to_string(arraySize) + "]";
        } 
       
        else 
        {
            return dataType;
        }
    }
 };
#endif