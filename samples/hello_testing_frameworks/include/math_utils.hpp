#pragma once
#include <exception>

namespace math_utils
{
    class DivisionByZeroError : public std::exception
    {
    public:
        const char* what() const noexcept override
        {
            return "Division by zero is not allowed";
        }
    };

    class NegativeFactorialError : public std::exception
    {
    public:
        const char* what() const noexcept override
        {
            return "Factorial is not defined for negative numbers";
        }
    };

    /**
     * @brief Add two integers
     * @param a First integer
     * @param b Second integer
     * @return Sum of a and b
     */
    int Add(int a, int b);

    /**
     * @brief Subtract two integers
     * @param a First integer
     * @param b Second integer
     * @return Difference of a and b
     */
    int Subtract(int a, int b);

    /**
     * @brief Multiply two integers
     * @param a First integer
     * @param b Second integer
     * @return Product of a and b
     */
    int Multiply(int a, int b);

    /**
     * @brief Divide two integers
     * @param a Dividend
     * @param b Divisor
     * @return Quotient of a and b
     * @throws math_utils::DivisionByZeroError if b is zero
     */
    int Divide(int a, int b);

    /**
     * @brief Check if a number is prime
     * @param n Number to check
     * @return true if n is prime, false otherwise
     */
    bool IsPrime(int n);

    /**
     * @brief Calculate factorial
     * @param n Non-negative integer
     * @return Factorial of n
     * @throws math_utils::NegativeFactorialError if n is negative
     */
    long long Factorial(int n);
}
