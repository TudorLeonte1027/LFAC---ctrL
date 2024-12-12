#include "SymTable.h"
using namespace std;

void SymTable::addVar(const char* type, const char*name) {
    IdInfo var(type, name, "var");
    ids[name] = var; 
}


bool SymTable::existsId(const char* var) {
    return ids.find(var)!= ids.end();  
}

void SymTable::printVars() {
    for (const pair<string, IdInfo>& v : ids) {
        cout << "name: " << v.first << " type:" << v.second.type << endl; 
     }
}

SymTable::~SymTable() {
    ids.clear();
}











