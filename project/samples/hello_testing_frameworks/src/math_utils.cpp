#include "math_utils.hpp"
#include <stdexcept>

namespace math_utils
{
    int Add(int a, int b)
    {
        return a + b;
    }

    int Subtract(int a, int b)
    {
        return a - b;
    }

    int Multiply(int a, int b)
    {
        return a * b;
    }

    int Divide(int a, int b)
    {
        if (b == 0)
        {
            throw std::invalid_argument("Division by zero is not allowed");
        }
        return a / b;
    }

    bool IsPrime(int n)
    {
        if (n < 2)
            return false;
        if (n == 2)
            return true;
        if (n % 2 == 0)
            return false;

        for (int i = 3; i * i <= n; i += 2)
        {
            if (n % i == 0)
                return false;
        }
        return true;
    }

    long long Factorial(int n)
    {
        if (n < 0)
        {
            throw std::invalid_argument("Factorial is not defined for negative numbers");
        }
        if (n == 0 || n == 1)
            return 1;

        long long result = 1;
        for (int i = 2; i <= n; ++i)
        {
            result *= i;
        }
        return result;
    }
} // namespace math_utils
