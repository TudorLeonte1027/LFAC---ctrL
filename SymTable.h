#include <iostream>
#include <map>
#include <string>

using namespace std;

class ParamList {
    //todo
};

class IdInfo {
    public:
    string idType;
    string type;
    string name;
    ParamList params; //for functions
    IdInfo() {}
    IdInfo(const char* type, const char* name, const char* idType) : type(type),name(name),idType(type) {}
};



class SymTable {
    map<string, IdInfo> ids;
    string name;
    public:
    SymTable(const char* name) :  name(name){}
    bool existsId(const char* s);
    void addVar(const char* type, const char* name );
    void printVars();
    ~SymTable();
};






