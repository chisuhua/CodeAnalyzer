#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendActions.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/Support/CommandLine.h"
#include <iostream>
#include <map>
#include <set>
#include <string>

using namespace clang;
using namespace clang::tooling;

// Structure to store inheritance information
struct InheritanceEdge {
    std::string derived;
    std::string base;
    std::string accessSpecifier;
};

// Visitor to traverse the AST and extract inheritance relationships
class InheritanceVisitor : public RecursiveASTVisitor<InheritanceVisitor> {
public:
    explicit InheritanceVisitor(ASTContext *context)
        : context(context) {}

    bool VisitCXXRecordDecl(CXXRecordDecl *decl) {
        // Skip forward declarations
        if (!decl->isThisDeclarationADefinition()) {
            return true;
        }

        // Skip template classes
        if (decl->getDescribedClassTemplate() != nullptr) {
            return true;
        }

        // Skip anonymous classes
        if (!decl->getIdentifier()) {
            return true;
        }

        std::string className = decl->getNameAsString();
        
        // Add the class to our set of classes
        classes.insert(className);

        // Extract base classes
        for (const auto &base : decl->bases()) {
            QualType baseType = base.getType();
            const CXXRecordDecl *baseDecl = baseType->getAsCXXRecordDecl();
            
            if (!baseDecl || !baseDecl->getIdentifier()) {
                continue;
            }

            std::string baseName = baseDecl->getNameAsString();
            
            // Get access specifier
            std::string accessSpec;
            switch (base.getAccessSpecifier()) {
                case AS_public:
                    accessSpec = "public";
                    break;
                case AS_protected:
                    accessSpec = "protected";
                    break;
                case AS_private:
                    accessSpec = "private";
                    break;
                default:
                    accessSpec = "private"; // default for class
                    break;
            }

            InheritanceEdge edge{className, baseName, accessSpec};
            edges.push_back(edge);
            classes.insert(baseName);
        }

        return true;
    }

    void printDOT() const {
        std::cout << "digraph InheritanceGraph {" << std::endl;
        std::cout << "    rankdir=BT;" << std::endl;
        std::cout << "    node [shape=box, style=filled, fillcolor=lightblue];" << std::endl;
        std::cout << std::endl;

        // Print nodes
        for (const auto &className : classes) {
            std::cout << "    \"" << className << "\";" << std::endl;
        }
        std::cout << std::endl;

        // Print edges
        for (const auto &edge : edges) {
            std::cout << "    \"" << edge.derived << "\" -> \"" << edge.base 
                      << "\" [label=\"" << edge.accessSpecifier << "\"];" << std::endl;
        }

        std::cout << "}" << std::endl;
    }

private:
    ASTContext *context;
    std::set<std::string> classes;
    std::vector<InheritanceEdge> edges;
};

// AST Consumer
class InheritanceConsumer : public ASTConsumer {
public:
    explicit InheritanceConsumer(ASTContext *context)
        : visitor(context) {}

    void HandleTranslationUnit(ASTContext &context) override {
        visitor.TraverseDecl(context.getTranslationUnitDecl());
        visitor.printDOT();
    }

private:
    InheritanceVisitor visitor;
};

// Frontend Action
class InheritanceAction : public ASTFrontendAction {
public:
    std::unique_ptr<ASTConsumer> CreateASTConsumer(
        CompilerInstance &compiler, StringRef file) override {
        return std::make_unique<InheritanceConsumer>(&compiler.getASTContext());
    }
};

// Command line options
static llvm::cl::OptionCategory InheritanceCategory("inheritance-extractor options");
static llvm::cl::extrahelp CommonHelp(CommonOptionsParser::HelpMessage);
static llvm::cl::extrahelp MoreHelp(
    "\nExtracts C++ inheritance relationships and outputs DOT format.\n"
    "Usage: inheritance_extractor <source-file> -- [compiler options]\n"
);

int main(int argc, const char **argv) {
    auto expectedParser = CommonOptionsParser::create(argc, argv, InheritanceCategory);
    if (!expectedParser) {
        llvm::errs() << expectedParser.takeError();
        return 1;
    }
    CommonOptionsParser &optionsParser = expectedParser.get();

    ClangTool tool(optionsParser.getCompilations(),
                   optionsParser.getSourcePathList());

    return tool.run(newFrontendActionFactory<InheritanceAction>().get());
}
