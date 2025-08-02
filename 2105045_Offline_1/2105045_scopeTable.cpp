#ifndef SCOPETABLE_CPP
#define SCOPETABLE_CPP

#include <bits/stdc++.h>
#include "2105045_symbolInfo.cpp"
#include "2105045_hashFunction.cpp"

using namespace std;

class ScopeTable
{
    private :
     

    SymbolInfo **Scope;
    
    unsigned int bucket_sizes;

    int scopeId;

    ScopeTable *parentScope;

    unsigned int (*hashFunction)(const std::string &, unsigned int);

    int collisionCount = 0;
   

public :

ScopeTable(unsigned int bucket_sizes, int scopeId, HashFunctionType hashType, ScopeTable *parentScope )
{
        this->bucket_sizes = bucket_sizes;

        this->parentScope = parentScope;

        this->scopeId = scopeId;

        this->hashFunction = getHashFunction(hashType);


        Scope = new SymbolInfo *[bucket_sizes];
        for (int i = 0; i < bucket_sizes; i++)
        {
            Scope[i] = nullptr;
        }

    }

    ~ScopeTable()
    {
        for (int i = 0; i < bucket_sizes; i++)

        {
            SymbolInfo *current = Scope[i];

            while (current != nullptr)

            {

                SymbolInfo *temporary = current;

                current = current->getNext();

                delete temporary;

            }
        }
        delete[] Scope;
    }

    bool Insert(string name, string type)
    {
        unsigned int index = hashFunction(name, bucket_sizes);
       
        int countValueOfPos = 1;

        SymbolInfo *current = Scope[index];

        SymbolInfo *previous = nullptr;


        while (current != nullptr)
        {
            if (current->getName() == name)
            {

                return false; 
            }

            previous = current;


            current = current->getNext();


            countValueOfPos++;


            


        }

        SymbolInfo *newSymbol = new SymbolInfo(name, type, scopeId, index + 1, countValueOfPos);

        if (previous == nullptr)
        {
            Scope[index] = newSymbol; 
        }
        else
        {   
            //tail insertion
            previous->setNext(newSymbol); 
            collisionCount++;

        
        }

        return true;
    }
    
    int getCollisionCount() 


    {
        
        
        return collisionCount; 

        
    }

    SymbolInfo *LookUp(string name)
    {
        unsigned  int index = hashFunction(name, bucket_sizes);


        SymbolInfo *current = Scope[index];


        while (current != nullptr)

        {
            if (current->getName() == name)
            {
                return current;
            }

            
            current = current->getNext();

        }

        return nullptr;
    }

    bool Delete(const string &name)
    {
        unsigned  int index = hashFunction(name, bucket_sizes);

        SymbolInfo *current = Scope[index];


        SymbolInfo *previous = nullptr;

        while (current != nullptr)
        {
            if (current->getName() == name)
            {
                if (previous == nullptr)
                {
                    Scope[index] = current->getNext();
                }
                else
                {
                    previous->setNext(current->getNext());
                }

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
        {
            cout << "\t";
        }
        cout << "ScopeTable# " << scopeId << endl;

       
        for (int i = 0; i < bucket_sizes; i++)
        {
            SymbolInfo *current = Scope[i];

            
            for (int j = 0; j < level; ++j)
            {
                cout << "\t";
            }

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

                    ss >> dummy;   
                    ss >> retType; 

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
                    {
                        members.emplace_back(t, var);
                    }

                   
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

    int getId()
    {
        
        return scopeId;


    }

    ScopeTable *getParentScope() 
    {
        
        return parentScope;


    }

    void setParentScope(ScopeTable *parent)
    {
        
        
        parentScope = parent;


    }




};

#endif