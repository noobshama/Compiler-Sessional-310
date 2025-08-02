#ifndef SCOPETABLE_CPP_GUARD
#define SCOPETABLE_CPP_GUARD

#include <bits/stdc++.h>
#include "2105045_symbolInfo.cpp"  

using namespace std;


static unsigned int sdbmHash(const char *p) {
    unsigned int hash = 0;
    const unsigned char *str = (const unsigned char *)p;
    int c;
    while ((c = *str++)) {
        hash = c + (hash << 6) + (hash << 16) - hash;
    }
    return hash;
}

class ScopeTable {
private:
    SymbolInfo **Scope;     
    unsigned int bucket_sizes;
    int scopeId;
    ScopeTable *parentScope;
    int collisionCount = 0;
    string scopeIdNum;

public:
    ScopeTable(unsigned int bucket_sizes, ScopeTable *parentScope, string scopeIdNumber)
    {
        this->bucket_sizes = bucket_sizes;
        this->parentScope = parentScope;
        scopeId = 0;

        Scope = new SymbolInfo *[bucket_sizes];
        for (unsigned int i = 0; i < bucket_sizes; i++)
        {
            Scope[i] = nullptr;
        }

        if (parentScope)
            scopeIdNum = scopeIdNumber + "." + to_string(parentScope->scopeId);
        else
            scopeIdNum = "1";
    }

    ~ScopeTable()
    {
        for (unsigned int i = 0; i < bucket_sizes; i++)
        {
            SymbolInfo *current = Scope[i];
            while (current != nullptr)
            {
                SymbolInfo *temp = current;
                current = current->getNext();
                delete temp;
            }
        }
        delete[] Scope;
    }

    
    unsigned int sdbmhash(const string &str)
    {
        unsigned int hashValue = sdbmHash(str.c_str());
        return hashValue % bucket_sizes;
    }

    bool Insert(const string &name, const string &type)
    {
        unsigned int index = sdbmhash(name);

        int countValueOfPos = 0;

        SymbolInfo *current = Scope[index];
        SymbolInfo *previous = nullptr;

        while (current != nullptr)
        {
            if (current->getName() == name)
                return false; // Already exists

            previous = current;
            current = current->getNext();
            countValueOfPos++;
        }

        SymbolInfo *newSymbol = new SymbolInfo(name, type, scopeId, index , countValueOfPos);

        if (previous == nullptr)
            Scope[index] = newSymbol;
        else
        {
            previous->setNext(newSymbol);
            collisionCount++;
        }

        return true;
    }
    bool InsertVariable(const string &name, const string &dataType, bool isArray = false, int arraySize = -1)
    {
        if (Insert(name, "ID")) {
            SymbolInfo* symbol = LookUp(name);
            if (symbol != nullptr) {
                symbol->setDataType(dataType);
                symbol->setIsArray(isArray);
                if (isArray) {
                    symbol->setArraySize(arraySize);
                }
                return true;
            }
        }
        return false;
    }
    bool InsertFunction(const string &name, FunctionInfo* funcInfo)
    {
        if (Insert(name, "ID")) {
            SymbolInfo* symbol = LookUp(name);
            if (symbol != nullptr) {
                symbol->setFunctionInfo(funcInfo);
                symbol->setDataType(funcInfo->getReturnType());
                return true;
            }
        }
        return false;
    }

    int getCollisionCount() {
        return collisionCount;
    }

    SymbolInfo *LookUp(const string &name)
    {
        unsigned int index = sdbmhash(name);
        SymbolInfo *current = Scope[index];
        while (current != nullptr)
        {
            if (current->getName() == name)
                return current;

            current = current->getNext();
        }
        return nullptr;
    }

    bool Delete(const string &name)
    {
        unsigned int index = sdbmhash(name);
        SymbolInfo *current = Scope[index];
        SymbolInfo *previous = nullptr;

        while (current != nullptr)
        {
            if (current->getName() == name)
            {
                if (previous == nullptr)
                    Scope[index] = current->getNext();
                else
                    previous->setNext(current->getNext());

                delete current;
                return true;
            }
            previous = current;
            current = current->getNext();
        }
        return false;
    }

    void print(int level)
    {
        for (int i = 0; i < level; ++i)
            cout << "\t";
        cout << "ScopeTable# " << scopeId << endl;

        for (unsigned int i = 0; i < bucket_sizes; i++)
        {
            SymbolInfo *current = Scope[i];

            for (int j = 0; j < level; ++j)
                cout << "\t";

            cout << i + 1 << "--> ";

            while (current != nullptr)
            {
                string name = current->getName();
                string type = current->getType();

                if (current->getIsFunction() && current->getFunctionInfo() != nullptr)
                {
                    FunctionInfo* funcInfo = current->getFunctionInfo();
                    cout << "<" << name << ",FUNCTION," << funcInfo->getReturnType() << "<==(";
                    
                    for (int k = 0; k < funcInfo->getParameterCount(); ++k)
                    {
                        cout << funcInfo->getParameterType(k);
                        if (k < funcInfo->getParameterCount() - 1)
                            cout << ",";
                    }
                    cout << ")> ";
                }
                else if (current->getIsArray())
                {
                    cout << "<" << name << "," << current->getDataType() << "[" << current->getArraySize() << "]> ";
                }
                else
                {
                    cout << "<" << name << "," << current->getDataType() << "> ";
                }

                current = current->getNext();
            }
            cout << endl;
        }
    }

    int getId() {
        return scopeId;
    }

    ScopeTable *getParentScope() {
        return parentScope;
    }

    void setParentScope(ScopeTable *parent) {
        parentScope = parent;
    }

    void Print(std::ofstream &fout) {
    fout << "ScopeTable # " << scopeIdNum << std::endl;
    
    for (unsigned int i = 0; i < bucket_sizes; i++) {
        SymbolInfo *current = Scope[i];
        if (current == nullptr) continue;  
        
        fout << i << " --> ";
        
        while (current != nullptr) {
            string name = current->getName();
            string type = current->getType();  
            fout << "< " << name << " : " << type << " >";
            
            current = current->getNext();
            
            
            
        }
        
        fout << std::endl;
    }
}
    

    string &getIdNum() {
        return scopeIdNum;
    }

    void incrementScopeId() {
        scopeId++;
    }

    bool hasMultipleDeclaration(const string &name) {
        return LookUp(name) != nullptr;
    }
    bool isFunction(const string &name) {
        SymbolInfo* symbol = LookUp(name);
        return symbol != nullptr && symbol->getIsFunction();
    }
    bool isArray(const string &name) {
        SymbolInfo* symbol = LookUp(name);
        return symbol != nullptr && symbol->getIsArray();
    }
    FunctionInfo* getFunctionInfo(const string &name) {
        SymbolInfo* symbol = LookUp(name);
        if (symbol != nullptr && symbol->getIsFunction()) {
            return symbol->getFunctionInfo();
        }
        return nullptr;
    }
    
};

#endif
