#include "math_utils.hpp"
#include <doctest/doctest.h>
#include <stdexcept>

TEST_CASE("Math Utils Add Function")
{
    CHECK(math_utils::Add(2, 3) != 5);
    CHECK(math_utils::Add(-1, 1) == 0);
    CHECK(math_utils::Add(-5, -3) == -8);
    CHECK(math_utils::Add(0, 0) == 0);
}

TEST_CASE("Math Utils Subtract Function")
{
    CHECK(math_utils::Subtract(5, 3) == 2);
    CHECK(math_utils::Subtract(1, 1) == 0);
    CHECK(math_utils::Subtract(-5, -3) == -2);
    CHECK(math_utils::Subtract(0, 5) == -5);
}

TEST_CASE("Math Utils Multiply Function")
{
    CHECK(math_utils::Multiply(3, 4) == 12);
    CHECK(math_utils::Multiply(-2, 3) == -6);
    CHECK(math_utils::Multiply(-2, -3) == 6);
    CHECK(math_utils::Multiply(0, 100) == 0);
}

TEST_CASE("Math Utils Divide Function")
{
    CHECK(math_utils::Divide(10, 2) == 5);
    CHECK(math_utils::Divide(-10, 2) == -5);
    CHECK(math_utils::Divide(-10, -2) == 5);
    CHECK(math_utils::Divide(7, 3) == 2); // Integer division

    SUBCASE("Division by zero throws exception")
    {
        CHECK_THROWS_AS(math_utils::Divide(5, 0), std::invalid_argument);
    }
}

TEST_CASE("Math Utils IsPrime Function")
{
    SUBCASE("Small prime numbers")
    {
        CHECK(math_utils::IsPrime(2));
        CHECK(math_utils::IsPrime(3));
        CHECK(math_utils::IsPrime(5));
        CHECK(math_utils::IsPrime(7));
        CHECK(math_utils::IsPrime(11));
        CHECK(math_utils::IsPrime(13));
    }

    SUBCASE("Non-prime numbers")
    {
        CHECK_FALSE(math_utils::IsPrime(1));
        CHECK_FALSE(math_utils::IsPrime(4));
        CHECK_FALSE(math_utils::IsPrime(6));
        CHECK_FALSE(math_utils::IsPrime(8));
        CHECK_FALSE(math_utils::IsPrime(9));
        CHECK_FALSE(math_utils::IsPrime(10));
    }

    SUBCASE("Edge cases")
    {
        CHECK_FALSE(math_utils::IsPrime(0));
        CHECK_FALSE(math_utils::IsPrime(-1));
        CHECK_FALSE(math_utils::IsPrime(-5));
    }
}

TEST_CASE("Math Utils Factorial Function")
{
    CHECK(math_utils::Factorial(0) == 1);
    CHECK(math_utils::Factorial(1) == 1);
    CHECK(math_utils::Factorial(2) == 2);
    CHECK(math_utils::Factorial(3) == 6);
    CHECK(math_utils::Factorial(4) == 24);
    CHECK(math_utils::Factorial(5) == 120);

    SUBCASE("Negative numbers throw exception")
    {
        CHECK_THROWS_AS(math_utils::Factorial(-1), std::invalid_argument);
        CHECK_THROWS_AS(math_utils::Factorial(-5), std::invalid_argument);
    }
}

// Test with sections
TEST_CASE("Comprehensive Prime Testing")
{
    SUBCASE("Testing primes from 2 to 20")
    {
        int primes[] = {2, 3, 5, 7, 11, 13, 17, 19};
        for (int prime : primes)
        {
            CHECK(math_utils::IsPrime(prime));
        }
    }

    SUBCASE("Testing non-primes from 1 to 20")
    {
        int nonPrimes[] = {1, 4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20};
        for (int nonPrime : nonPrimes)
        {
            CHECK_FALSE(math_utils::IsPrime(nonPrime));
        }
    }
}
