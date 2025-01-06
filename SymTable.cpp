
#include <fstream>
#include "SymbolTable.h"


Variable::Variable(string type, string name, string scope, int lineno): type(type), name(name), scope(scope), lineno(lineno)
{
    if (this->type == "int") value = new IntValue(0);
    else if (this->type == "bool") value = new BoolValue(false);
    else if (this->type == "float") value = new FloatValue(0.0);
    else if (this->type == "char") value = new CharValue('\0');
    else if (this->type == "string") value = new StringValue("");
    else value = nullptr;
}

void Variable::setValue(Value* val)
{
    value = val;
}

Value* Variable::getValue()
{
    return value;
}

void Variable::setConstant()
{
    this->constant = true;
}

/*static*/ SymbolTable* SymbolTable::instance = nullptr;

/*static*/ SymbolTable* SymbolTable::getInstance()
{
    if (instance == nullptr)
    {
        instance = new SymbolTable();
    }

    return instance;
}

SymbolTable::SymbolTable() {}

SymbolTable::~SymbolTable() {}

bool SymbolTable::existsVar(const char* s)
{
    return vars[s]!=nullptr;
}

Variable* SymbolTable::addVariable(const char* type, const char* name, const char* scope, int lineno)
{
    // printf("Adding variable %s of type %s at line %d\n", name, type, lineno);
    Variable* v = vars[name];
    if (v == nullptr)
    {
        v = new Variable(type, name, scope, lineno);
        vars[name] = v;
    } 
    else
    {
        cout <<"line : " <<lineno <<" ERR: Duplicate variable " << name << " already declared at line " << v->getLine() <<endl;
        exit(-6);
    }
    return v;
}

Variable* SymbolTable::getVariable(string name)
{
    if (crtFunction != nullptr)
    {
        Variable* v = crtFunction->getLocals()[name];
        if (v != nullptr)
        {
            return v;
        }
    }
    return vars[name];
}

// Iterate through the map and print the elements
void SymbolTable::printVars()
{
    ofstream fout("Variables.txt");

    fout << "Variables:"<< endl;
    fout << "LineNo\tType\tVarName\tValue\tScope"<< endl;
    auto it = vars.begin();
    while (it != vars.end())
    {
        Variable* var = it->second;
        string stringValue = "(null)";
        if (var->getValue() != nullptr)
        {
            stringValue = var->getValue()->stringValue();
        }
        char is_const = var->isConstant()?'*':' ' ;
        fout<< var->getLine() <<"\t" << var->getType() <<is_const << "\t" << var->getName() << "\t" << stringValue << "\t" << var->getScope() << endl;
        ++it;
    }

    fout << endl;
    fout << "Functions:" << endl;
    fout << "LineNo\tType\tFnName\tParameterTypes"<< endl;

    auto it3 = funcs.begin();
    while (it3 != funcs.end())
    {
        Function* var = it3->second;
        fout << var->getLine() <<"\t" << var->getType() << "\t" << var->getName() << "\t(";
        list<Parameter*>* params = var->getParameters();
        
        auto it2 = params->begin();
        while (it2 != params->end())
        {
            Parameter* p = *it2;
            fout << p->getType();
            ++it2;
            if (it2 != params->end())
                fout << ", ";
        }
        fout << ")" << endl;

        ++it3;
    }

    fout << endl;
    fout << "Classes:" << endl;
    fout << "LineNo\tObjectName" << endl;

    auto it4 = objects.begin();
    while (it4 != objects.end())
    {
        Object* obj = it4->second;
        fout << obj->getLine() << "\t" << obj->getName() << endl;
        ++it4;
    }
    fout.close();
}

Function* SymbolTable::addFunction(const char* type, const char* name, list<Parameter*>* params, list<Statement*>* stmts, int lineno)
{
    Function* f = funcs[name];
    if (f == nullptr)
    {
        funcs[name] = new Function(name, type, params, stmts, lineno);
    }
    else
    {
        cout << "line : " << lineno << " ERR: Duplicate function " << name << 
                " already declared at line " << f->getLine() <<endl;
        exit(-5);
    }
    return f;
}

Function* SymbolTable::getFunction(string name)
{
    return funcs[name];
} 

Function* SymbolTable::setCurrentFunction(Function* f)
{
    Function* saveFn = crtFunction;
    crtFunction = f;
    return saveFn;
}

Object* SymbolTable::getObject(string name)
{
    return objects[name];
}

Object* SymbolTable::addObject(string name, int lineno)
{
    Object* o = objects[name];
    if (o == nullptr)
    {
        objects[name] = new Object(name, lineno);
    }
    else
    {
        cout << "line:"<< lineno << "ERR: Duplicate object " << name << " already declared." <<endl;
        exit(-7);
    }
    return o;
}

void SymbolTable::setReturnValue(Value* v)
{
    if (crtFunction == nullptr)
    {
        cout << "ERR: invalid return statement." <<endl;
        exit(-18);
    }
    crtFunction->setReturnValue(v);
}

Value* Function::execute(list<AST*>* args)
{
    // match arguments with parameters
    if (args->size() != params->size())
    {
        cout <<"line : " << lineno << " ERR: incorrect number of arguments in '" << name << "' function call." <<endl;
        exit(-17);
    }
    auto itArg = args->begin();
    auto itParam = params->begin();
    while (itArg != args->end())
    {
        Parameter* p = *itParam;
        AST* arg = *itArg;
        string arg_type = arg->getType();
        if (arg_type != p->getType())
        {
            cout << "line : " << p->getLine() << " ERR: incorrect type of argument " << p->getName()
                    << " in '" << name << "' function call." <<endl << "Parameter type is : " 
                    << p->getType() << " Argument type is : " << arg_type << endl;
            exit(-17);
        }
        // evaluate arguments and add arguments as variables
        Variable* v = new Variable(arg_type, p->getName(), p->getScope(), p->getLine());
        local_vars[p->getName()] = v;
        v->setValue(arg->getValue());

        ++itArg;
        ++itParam;
    }

    Function* prevFunction = SymbolTable::getInstance()->setCurrentFunction(this);
    
    // execute statements
    auto it = stmts->begin();
    while (it != stmts->end())
    {
        Statement* stmt = *it;
        stmt->run();
        if (retVal != nullptr)
            break;
        ++it;
    }

    SymbolTable::getInstance()->setCurrentFunction(prevFunction);

    return retVal;
}

void Function::setReturnValue(Value* v)
{
    retVal = v;
}
