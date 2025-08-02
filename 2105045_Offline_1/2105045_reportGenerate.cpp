#include <bits/stdc++.h>
using namespace std;

void execute_command( const string &hash_choice) 

{
    string command = "g++ -fsanitize=address -g -o 2105045_main 2105045_main.cpp";


    if (system(command.c_str()) != 0)
    
    {
        cerr << " Compilation failed for hash " << hash_choice << endl;
        exit(1);
    }

    command = "./2105045_main sample_input.txt output.txt " + hash_choice;


    if (system(command.c_str()) != 0) 
    
    {
        cerr << " Execution failed for hash " << hash_choice<< endl;
        exit(1);
    }
}

int main() 
{
    ofstream logFile("log.txt", ios::app);


    if (!logFile) 
    {
        cerr << "Failed to open log file!" << endl;
        return 1;
    }

    vector<string> hash_functions = {"SDBM", "Murmur", "FNV1a"};


    for (const auto &hash_choice : hash_functions)
    
    {
        execute_command(hash_choice);

        logFile << "[DONE] " << hash_choice << endl;
        logFile << "-----------------------------------" << endl;
    }

    logFile.close();


    return 0;
}
