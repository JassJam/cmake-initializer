#include "math_utils.hpp"
#include <iostream>

int main()
{
    std::cout << "Hello Testing Frameworks Demo\n";
    std::cout << "============================\n\n";

    // Demonstrate some math operations
    std::cout << "Math Operations Demo:\n";
    std::cout << "5 + 3 = " << math_utils::Add(5, 3) << "\n";
    std::cout << "10 - 4 = " << math_utils::Subtract(10, 4) << "\n";
    std::cout << "6 * 7 = " << math_utils::Multiply(6, 7) << "\n";
    std::cout << "15 / 3 = " << math_utils::Divide(15, 3) << "\n";

    std::cout << "\nPrime Number Check:\n";
    for (int i = 2; i <= 10; ++i)
    {
        std::cout << i << " is " << (math_utils::IsPrime(i) ? "prime" : "not prime") << "\n";
    }

    std::cout << "\nFactorial Demo:\n";
    for (int i = 0; i <= 5; ++i)
    {
        std::cout << i << "! = " << math_utils::Factorial(i) << "\n";
    }

    std::cout << "\nRun tests to verify the implementation!\n";
    return 0;
}
