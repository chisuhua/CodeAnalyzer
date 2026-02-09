// Advanced test file demonstrating multiple inheritance and various features

// Base class
class Vehicle {
public:
    virtual void move() {}
};

// Another base class
class Engine {
protected:
    virtual void start() {}
};

// Multiple inheritance
class Car : public Vehicle, private Engine {
public:
    void drive() {}
};

// Protected inheritance
class Bicycle : protected Vehicle {
public:
    void pedal() {}
};

// Deep inheritance hierarchy
class ElectricCar : public Car {
public:
    void charge() {}
};

// Template class (should be ignored)
template<typename T>
class Container {
public:
    T data;
};

// Normal class using template (should be included)
class DataHolder {
private:
    int value;
};

// Struct with public inheritance (default)
struct Motorcycle : Vehicle {
    void rev() {}
};
