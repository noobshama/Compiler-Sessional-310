#ifndef FUNCTIONINFO_CPP_GUARD
#define FUNCTIONINFO_CPP_GUARD

#include <bits/stdc++.h>

using namespace std;

class Parameter{
    
    public :

    string name;
    string type;

    Parameter()
    {

    }

    Parameter(string name , string type)

    {
        this->name = name;
        this->type = type;
    }
};


class FunctionInfo{

    private:
    string returnType;
    vector<Parameter> parameters;
    bool isDefined;
    bool isDeclared;
    int definitionLine;
    int declarationLine;


    public:

    FunctionInfo()
    {
        this->returnType = "";
        this->isDefined = false;
        this->isDeclared = false;
        this->definitionLine = -1;
        this->declarationLine = -1;     
    }
    FunctionInfo(string retType)
    {
        returnType = retType;
        isDefined = false;
        isDeclared = false;
        definitionLine = -1;
        declarationLine = -1;

    }

    string getReturnType() const
    {
        return returnType;
    }
    vector<Parameter> getParameters() const
     { 
        return parameters; 
     }
     bool getIsDefined() const 
     {  
        return isDefined;
     }

     bool getIsDeclared() const 
     { 
        return isDeclared;
     }
     int getDefinitionLine() const 
     { 
        return definitionLine;
     }
     int getDeclarationLine() const
      { 
        return declarationLine; 
      }
      int getParameterCount() const 
      { 
        return parameters.size(); 
     }
     void setReturnType(string retType) 
        { 
            returnType = retType; 
        }
     void setIsDefined(bool defined)
         {
             isDefined = defined;
         }
        void setIsDeclared(bool declared)
            {
                isDeclared = declared;
            }
        void setDefinitionLine(int line)
            {
                definitionLine = line;
            }
        void setDeclarationLine(int line)
            {
                declarationLine = line;
            }

            void addParameter(string type, string name) 
            {
                parameters.push_back(Parameter(type, name));
            }
            void clearParameters() 
            {
                parameters.clear();
            }

            Parameter getParameter(int index) const 
            {
                if (index >= 0 && index < parameters.size()) 
                {
                    return parameters[index];
                }
                return Parameter("", "");
            }

            string getParameterType(int index) const
             {
                if (index >= 0 && index < parameters.size())
             {
                    return parameters[index].type;
                }
                return "";
            }
            string getParameterName(int index) const 
            {
                if (index >= 0 && index < parameters.size()) 
                {
                    return parameters[index].name;
                }
                return "";
            }
            bool matchesSignature(const FunctionInfo& other) const 
            {
                if (returnType != other.returnType)
             {
                    return false;
                }
                if (parameters.size() != other.parameters.size()) 
                { 
                     return false;
                }
                
                for (size_t i = 0; i < parameters.size(); i++) {
                    if (parameters[i].type != other.parameters[i].type) {
                        return false;
                    }
                }
                return true;
            }

            string getFunctionSignature() const 
            {
                string signature = returnType + " (";
                for (size_t i = 0; i < parameters.size(); i++) {
                    if (i > 0) signature += ", ";
                    signature += parameters[i].type;
                    if (!parameters[i].name.empty()) {
                        signature += " " + parameters[i].name;
                    }
                }
                signature += ")";
                return signature;
            }





};

#endif