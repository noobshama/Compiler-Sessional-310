#include "2105045_symbolTable.cpp"
#include "2105045_hashFunction.cpp"
#include "2105045_symbolInfo.cpp"
#include "2105045_scopeTable.cpp"
#include <bits/stdc++.h>

using namespace std;

int main(int argc, char *argv[])
{
    // Check if correct number of arguments are provided
    if (argc < 3)
    {
        cerr << "Usage: " << argv[0] << " <input_file> <output_file>" << endl;
        return 1;
    }

    string inputFile = argv[1];
    string outputFile = argv[2];

    HashFunctionType hashType = HashFunctionType::SDBM;

    if (argc > 3)
    {
        string hashChoice = argv[3];

        if (hashChoice == "SDBM")
        {
            hashType = HashFunctionType::SDBM;
        }
        else if (hashChoice == "Murmur")
        {
            hashType = HashFunctionType::Murmur;
        }
        
        else if (hashChoice == "FNV1a")
        {
            hashType = HashFunctionType::FNV1a;
        }
        else
        {
            cout << "Invalid hash function choice provided. Using default SDBM." << endl;
        }
    }
    else
    {
        cout << "No hash function provided. Using default SDBM." << endl;
    }

    // Open the input and output files
    ifstream input(inputFile);
    ofstream output(outputFile);

    streambuf *cinbuf = cin.rdbuf();
    streambuf *coutbuf = cout.rdbuf();

    cin.rdbuf(input.rdbuf());
    cout.rdbuf(output.rdbuf());

    if (!input.is_open())
    {
        cerr << "Error: Could not open input file: " << inputFile << endl;
        return 1;
    }

    if (!output.is_open())
    {
        cerr << "Error: Could not open output file: " << outputFile << endl;
        return 1;
    }

    int bucketSize;
    input >> bucketSize;
    input.ignore();

    SymbolTable symbolTable(bucketSize, hashType);

    char command;
    int numberOfCommands = 1;
    string line;

    while (getline(input, line))
    {
        istringstream iss(line);
        iss >> command;

        switch (command)
        {
        case 'I':
        {
            string name, type;
            iss >> name >> type;

            if (type == "FUNCTION")
            {
                string returnType, arg, fullType;
                if (!(iss >> returnType))
                {
                    output << "Cmd " << numberOfCommands << ": " << line << endl
                           << "\tMissing return type for FUNCTION" << endl;
                    break;
                }

                fullType = "FUNCTION " + returnType;
                while (iss >> arg)
                {
                    fullType += " " + arg;
                }

                output << "Cmd " << numberOfCommands << ": " << line << endl;
                bool inserted = symbolTable.Insert(name, fullType);
                SymbolInfo *info = symbolTable.LookUp(name);

                if (inserted && info != nullptr)
                {
                    output << "\tInserted in ScopeTable# "
                           << info->getScopeTableIndex() << " at position "
                           << info->getHashIndex() << ", "
                           << info->getLinkedListIndex() << endl;
                }
                else
                {
                    output << "\t'" << name << "' already exists in the current ScopeTable" << endl;
                }
            }
            else if (type == "STRUCT" || type == "UNION")
            {
                string t, var, fullType = type;
                set<string> uniqueNames; 
            
                bool invalidArgument = false;
                
                while (iss >> t >> var)
                {
                    
                    if (uniqueNames.find(var) != uniqueNames.end())
                    {
                        output << "Cmd " << numberOfCommands << ": " << line << endl
                               << "\tVariable name '" << var << "' is repeated in the " << type << endl;
                        invalidArgument = true;
                        break;
                    }
            
                   
                    uniqueNames.insert(var);
            
                    fullType += " " + t + " " + var;
                }
            
                if (!invalidArgument)
                {
                    output << "Cmd " << numberOfCommands << ": " << line << endl;
                    bool inserted = symbolTable.Insert(name, fullType);
                    SymbolInfo *info = symbolTable.LookUp(name);
            
                    if (inserted && info != nullptr)
                    {
                        output << "\tInserted in ScopeTable# "
                               << info->getScopeTableIndex() << " at position "
                               << info->getHashIndex() << ", "
                               << info->getLinkedListIndex() << endl;
                    }
                    else
                    {
                        output << "\t'" << name << "' already exists in the current ScopeTable" << endl;
                    }
                }
            }
            
            else
            {
                string extra;
                if (iss >> extra)
                {
                    output << "Cmd " << numberOfCommands << ": " << line << endl
                           << "\tWrong number of arguments for the command I" << endl;
                    break;
                }

                output << "Cmd " << numberOfCommands << ": I " << name << " " << type << endl;
                bool result = symbolTable.Insert(name, type);
                SymbolInfo *found = symbolTable.LookUp(name);

                if (result && found != nullptr)
                {
                    output << "\tInserted in ScopeTable# "
                           << found->getScopeTableIndex() << " at position "
                           << found->getHashIndex() << ", "
                           << found->getLinkedListIndex() << endl;
                }
                else
                {
                    output << "\t'" << name << "' already exists in the current ScopeTable" << endl;
                }
            }

            break;
        }

        case 'L':
        {
            string name;

            if (!(iss >> name) || iss.rdbuf()->in_avail() > 0)
            {
                output << "Cmd " << numberOfCommands << ": " << line << endl
                       << "\tNumber of parameters mismatch for the command L" << endl;
                break;
            }

            output << "Cmd " << numberOfCommands << ": L " << name << endl;
            SymbolInfo *found = symbolTable.LookUp(name);

            if (found != nullptr)
            {
                output << "\t'" << name << "' found in ScopeTable# "
                       << found->getScopeTableIndex() << " at position "
                       << found->getHashIndex() << ", "
                       << found->getLinkedListIndex() << endl;
            }
            else
            {
                output << "\t'" << name << "' not found in any of the ScopeTables" << endl;
            }

            break;
        }

        case 'D':
        {
            string name;

            if (!(iss >> name) || iss.rdbuf()->in_avail() > 0)
            {
                output << "Cmd " << numberOfCommands << ": " << line << endl
                       << "\tNumber of parameters mismatch for the command D" << endl;
                break;
            }

            output << "Cmd " << numberOfCommands << ": D " << name << endl;
            SymbolInfo *found = symbolTable.LookUpInCurrentScope(name);

            if (found != nullptr)
            {
                output << "\tDeleted '" << name << "' from ScopeTable# "
                       << symbolTable.getCurrentScopeId() << " at position "
                       << found->getHashIndex() << ", "
                       << found->getLinkedListIndex() << endl;
                symbolTable.Remove(name);
            }
            else
            {
                output << "\tNot found in the current ScopeTable" << endl;
            }

            break;
        }

        case 'P':
        {
            char subCommand;
            if (!(iss >> subCommand) || iss.rdbuf()->in_avail() > 0)
            {
                output << "Cmd " << numberOfCommands << ": " << line << endl
                       << "\tWrong number of arguments for the command P" << endl;
                break;
            }

            output << "Cmd " << numberOfCommands << ": P " << subCommand << endl;

            if (subCommand == 'C')
            {
                symbolTable.printCurrentScope();
            }
            else if (subCommand == 'A')
            {
                symbolTable.printAllScopes();
            }
            else
            {
                output << "\tInvalid argument for the command P" << endl;
            }

            break;
        }

        case 'S':
        {
            if (iss.rdbuf()->in_avail() > 0)
            {
                output << "Cmd " << numberOfCommands << ": " << line << endl
                       << "\tWrong number of arguments for the command S" << endl;
                break;
            }

            output << "Cmd " << numberOfCommands << ": S" << endl;
            symbolTable.EnterScope(bucketSize, hashType);
            break;
        }

        case 'E':
        {
            if (iss.rdbuf()->in_avail() > 0)
            {
                output << "Cmd " << numberOfCommands << ": " << line << endl
                       << "\tWrong number of arguments for the command E" << endl;
                break;
            }

            output << "Cmd " << numberOfCommands << ": E" << endl;
            symbolTable.ExitScope();
            break;
        }

        case 'Q':
        {
           
            if (iss.rdbuf()->in_avail() > 0)
            {
                output << "Cmd " << numberOfCommands << ": " << line << endl
                       << "\tWrong number of arguments for the command Q" << endl;
            }
            else
            {
                output << "Cmd " << numberOfCommands << ": Q" << endl;
                symbolTable.exitAllScope();
        
                
                ofstream logFile("log.txt", ios::app);
                if (!logFile.is_open())
                {
                    cerr << "Failed to open log file!" << endl;
                    return 1;
                }
        
                int scopeCount = symbolTable.getScopeCount();
                int collisionCount = symbolTable.getTotalCollisionCount();
                int bucket_Size = bucketSize;
        
                double Qality = (double)collisionCount / bucket_Size; 
                double Mean = scopeCount > 1 ? Qality / scopeCount : 0.0; 
        
                logFile << "Hash Function: " << (hashType == HashFunctionType::SDBM ? "SDBM" :
                                                 hashType == HashFunctionType::Murmur ? "Murmur" : "FNV1a") << endl;
                logFile << "Scope Count: " << scopeCount << endl;
                logFile << "Collision Count: " << collisionCount << endl;
                logFile << "Bucket Size: " << bucket_Size << endl;
                logFile << "Qality : " << Qality << endl;
                if (scopeCount > 1)
                    logFile << "Mean : " << Mean << endl;
                logFile << "-----------------------------------" << endl;
        
                logFile.close();
        
               
                exit(0);
            }
            break;
        }
        

        default:
            output << "Cmd " << numberOfCommands << ": " << line << endl
                   << "\tInvalid command" << endl;
            break;
        }

        numberOfCommands++;
    }

    cin.rdbuf(cinbuf);
    cout.rdbuf(coutbuf);
    return 0;
}
