#ifndef SCOPETABLE_CPP
#define SCOPETABLE_CPP

#include <bits/stdc++.h>
#include "2105045_symbolInfo.cpp"  

using namespace std;


unsigned int sdbmHash(const char *p) {
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

                if (type.substr(0, 8) == "FUNCTION")
                {
                    stringstream ss(type);
                    string dummy, retType;
                    vector<string> args;

                    ss >> dummy;   // FUNCTION
                    ss >> retType; // Return type

                    string arg;
                    while (ss >> arg)
                        args.push_back(arg);

                    cout << "<" << name << ",FUNCTION," << retType << "<==(";
                    for (size_t k = 0; k < args.size(); ++k)
                    {
                        cout << args[k];
                        if (k < args.size() - 1)
                            cout << ",";
                    }
                    cout << ")> ";
                }
                else if (type.substr(0, 6) == "STRUCT" || type.substr(0, 5) == "UNION")
                {
                    string header;
                    stringstream ss(type);
                    ss >> header; 

                    vector<pair<string, string>> members;
                    string t, var;
                    while (ss >> t >> var)
                        members.emplace_back(t, var);

                    cout << "<" << name << "," << header << ",{";
                    for (size_t k = 0; k < members.size(); ++k)
                    {
                        cout << "(" << members[k].first << "," << members[k].second << ")";
                        if (k < members.size() - 1)
                            cout << ",";
                    }
                    cout << "}> ";
                }
                else
                {
                    cout << "<" << name << "," << type << "> ";
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

    void Print(FILE *fout)
    {
        fprintf(fout, "ScopeTable # %s\n", scopeIdNum.c_str());
    
        for (unsigned int i = 0; i < bucket_sizes; i++)
        {
            SymbolInfo *current = Scope[i];
            if (current == nullptr) continue;  
            fprintf(fout, "%d --> ", i);
    
            while (current != nullptr)
            {
                string name = current->getName();
                string type = current->getType();
    
                fprintf(fout, "< %s : %s >", name.c_str(), type.c_str());
    
                current = current->getNext();
            }
    
            fprintf(fout, "\n");
        }
       
    }
    

    string &getIdNum() {
        return scopeIdNum;
    }

    void incrementScopeId() {
        scopeId++;
    }
};

#endif
