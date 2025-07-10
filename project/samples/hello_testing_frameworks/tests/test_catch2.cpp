#include "math_utils.hpp"
#include <catch2/catch_test_macros.hpp>
#include <stdexcept>

TEST_CASE("Math Utils Add Function", "[add]")
{
    REQUIRE(math_utils::Add(2, 3) == 5);
    REQUIRE(math_utils::Add(-1, 1) == 0);
    REQUIRE(math_utils::Add(-5, -3) == -8);
    REQUIRE(math_utils::Add(0, 0) == 0);
}

TEST_CASE("Math Utils Subtract Function", "[subtract]")
{
    REQUIRE(math_utils::Subtract(5, 3) == 2);
    REQUIRE(math_utils::Subtract(1, 1) == 0);
    REQUIRE(math_utils::Subtract(-5, -3) == -2);
    REQUIRE(math_utils::Subtract(0, 5) == -5);
}

TEST_CASE("Math Utils Multiply Function", "[multiply]")
{
    REQUIRE(math_utils::Multiply(3, 4) == 12);
    REQUIRE(math_utils::Multiply(-2, 3) == -6);
    REQUIRE(math_utils::Multiply(-2, -3) == 6);
    REQUIRE(math_utils::Multiply(0, 100) == 0);
}

TEST_CASE("Math Utils Divide Function", "[divide]")
{
    REQUIRE(math_utils::Divide(10, 2) == 5);
    REQUIRE(math_utils::Divide(-10, 2) == -5);
    REQUIRE(math_utils::Divide(-10, -2) == 5);
    REQUIRE(math_utils::Divide(7, 3) == 2); // Integer division

    SECTION("Division by zero throws exception")
    {
        REQUIRE_THROWS_AS(math_utils::Divide(5, 0), std::invalid_argument);
    }
}

TEST_CASE("Math Utils IsPrime Function", "[prime]")
{
    SECTION("Small prime numbers")
    {
        REQUIRE(math_utils::IsPrime(2));
        REQUIRE(math_utils::IsPrime(3));
        REQUIRE(math_utils::IsPrime(5));
        REQUIRE(math_utils::IsPrime(7));
        REQUIRE(math_utils::IsPrime(11));
        REQUIRE(math_utils::IsPrime(13));
    }

    SECTION("Non-prime numbers")
    {
        REQUIRE_FALSE(math_utils::IsPrime(1));
        REQUIRE_FALSE(math_utils::IsPrime(4));
        REQUIRE_FALSE(math_utils::IsPrime(6));
        REQUIRE_FALSE(math_utils::IsPrime(8));
        REQUIRE_FALSE(math_utils::IsPrime(9));
        REQUIRE_FALSE(math_utils::IsPrime(10));
    }

    SECTION("Edge cases")
    {
        REQUIRE_FALSE(math_utils::IsPrime(0));
        REQUIRE_FALSE(math_utils::IsPrime(-1));
        REQUIRE_FALSE(math_utils::IsPrime(-5));
    }
}

TEST_CASE("Math Utils Factorial Function", "[factorial]")
{
    REQUIRE(math_utils::Factorial(0) == 1);
    REQUIRE(math_utils::Factorial(1) == 1);
    REQUIRE(math_utils::Factorial(2) == 2);
    REQUIRE(math_utils::Factorial(3) == 6);
    REQUIRE(math_utils::Factorial(4) == 24);
    REQUIRE(math_utils::Factorial(5) == 120);

    SECTION("Negative numbers throw exception")
    {
        REQUIRE_THROWS_AS(math_utils::Factorial(-1), std::invalid_argument);
        REQUIRE_THROWS_AS(math_utils::Factorial(-5), std::invalid_argument);
    }
}
