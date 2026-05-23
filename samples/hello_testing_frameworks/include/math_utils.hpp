#pragma once

namespace math_utils
{
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
     * @throws std::invalid_argument if b is zero
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
     * @throws std::invalid_argument if n is negative
     */
    long long Factorial(int n);
}
