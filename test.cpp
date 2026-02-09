// Test file demonstrating C++ inheritance relationships
// This should produce 3 nodes and 2 edges in the inheritance graph

class Animal {
public:
    virtual void speak() {}
};

class Dog : public Animal {
public:
    void speak() override {}
};

class Cat : private Animal {
public:
    void speak() override {}
};
