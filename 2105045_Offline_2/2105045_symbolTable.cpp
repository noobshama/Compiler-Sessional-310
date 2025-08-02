#ifndef SYMBOLTABLE_CPP
#define SYMBOLTABLE_CPP
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


    void printCurrentScope(FILE *fout) 
    {

        currentScope->Print(fout);


    }

    void printAllScopes(FILE *fout) 
    {
        ScopeTable *scope = currentScope;
        //int level = 1; 

        while (scope != nullptr)
        {
           

            //scope->print(level); 
            scope->Print(fout);


            scope = scope->getParentScope();


          //  level++; 


        }
        fprintf(fout, "\n");
    }

    string getCurrentScopeId() 

    {

        return currentScope->getIdNum();


    }

    ScopeTable *getCurrentScope() 
    {

        return currentScope;


    }
    

};
#endif