#ifndef SYMBOLINFO_CPP
#define SYMBOLINFO_CPP
#include <bits/stdc++.h>

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

    public :


    SymbolInfo(string name , string type, int scopeTableIndex, unsigned int hashIndex , int linkedListIndex )
    {
        this->name = name;


        this->type = type;

        this->scopeTableIndex = scopeTableIndex;


        this->hashIndex = hashIndex;


        this->linkedListIndex = linkedListIndex;


        next = nullptr;
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
    
};
#endif