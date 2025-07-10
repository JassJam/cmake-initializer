#include "math_utils.hpp"
#include <gtest/gtest.h>
#include <stdexcept>

class MathUtilsTest : public ::testing::Test
{
protected:
    void SetUp() override
    {
    }
    void TearDown() override
    {
    }
};

TEST_F(MathUtilsTest, TestAdd)
{
    EXPECT_EQ(math_utils::Add(2, 3), 5);
    EXPECT_EQ(math_utils::Add(-1, 1), 0);
    EXPECT_EQ(math_utils::Add(-5, -3), -8);
    EXPECT_EQ(math_utils::Add(0, 0), 0);
}

TEST_F(MathUtilsTest, TestSubtract)
{
    EXPECT_EQ(math_utils::Subtract(5, 3), 2);
    EXPECT_EQ(math_utils::Subtract(1, 1), 0);
    EXPECT_EQ(math_utils::Subtract(-5, -3), -2);
    EXPECT_EQ(math_utils::Subtract(0, 5), -5);
}

TEST_F(MathUtilsTest, TestMultiply)
{
    EXPECT_EQ(math_utils::Multiply(3, 4), 12);
    EXPECT_EQ(math_utils::Multiply(-2, 3), -6);
    EXPECT_EQ(math_utils::Multiply(-2, -3), 6);
    EXPECT_EQ(math_utils::Multiply(0, 100), 0);
}

TEST_F(MathUtilsTest, TestDivide)
{
    EXPECT_EQ(math_utils::Divide(10, 2), 5);
    EXPECT_EQ(math_utils::Divide(-10, 2), -5);
    EXPECT_EQ(math_utils::Divide(-10, -2), 5);
    EXPECT_EQ(math_utils::Divide(7, 3), 2); // Integer division

    // Test division by zero exception
    EXPECT_THROW(math_utils::Divide(5, 0), std::invalid_argument);
}

TEST_F(MathUtilsTest, TestIsPrime)
{
    // Test small primes
    EXPECT_TRUE(math_utils::IsPrime(2));
    EXPECT_TRUE(math_utils::IsPrime(3));
    EXPECT_TRUE(math_utils::IsPrime(5));
    EXPECT_TRUE(math_utils::IsPrime(7));
    EXPECT_TRUE(math_utils::IsPrime(11));
    EXPECT_TRUE(math_utils::IsPrime(13));

    // Test non-primes
    EXPECT_FALSE(math_utils::IsPrime(1));
    EXPECT_FALSE(math_utils::IsPrime(4));
    EXPECT_FALSE(math_utils::IsPrime(6));
    EXPECT_FALSE(math_utils::IsPrime(8));
    EXPECT_FALSE(math_utils::IsPrime(9));
    EXPECT_FALSE(math_utils::IsPrime(10));

    // Test negative numbers and zero
    EXPECT_FALSE(math_utils::IsPrime(0));
    EXPECT_FALSE(math_utils::IsPrime(-1));
    EXPECT_FALSE(math_utils::IsPrime(-5));
}

TEST_F(MathUtilsTest, TestFactorial)
{
    EXPECT_EQ(math_utils::Factorial(0), 1);
    EXPECT_EQ(math_utils::Factorial(1), 1);
    EXPECT_EQ(math_utils::Factorial(2), 2);
    EXPECT_EQ(math_utils::Factorial(3), 6);
    EXPECT_EQ(math_utils::Factorial(4), 24);
    EXPECT_EQ(math_utils::Factorial(5), 120);

    // Test negative number exception
    EXPECT_THROW(math_utils::Factorial(-1), std::invalid_argument);
    EXPECT_THROW(math_utils::Factorial(-5), std::invalid_argument);
}

// Parameterized test example
class PrimeNumberTest : public ::testing::TestWithParam<std::pair<int, bool>>
{
};

TEST_P(PrimeNumberTest, IsPrimeParameterized)
{
    auto [number, expected] = GetParam();
    EXPECT_EQ(math_utils::IsPrime(number), expected);
}

INSTANTIATE_TEST_SUITE_P(          //
    PrimeNumbers,                  //
    PrimeNumberTest,               //
    ::testing::Values(             //
        std::make_pair(2, true),   //
        std::make_pair(3, true),   //
        std::make_pair(4, false),  //
        std::make_pair(5, true),   //
        std::make_pair(6, false),  //
        std::make_pair(7, true),   //
        std::make_pair(8, false),  //
        std::make_pair(9, false),  //
        std::make_pair(10, false), //
        std::make_pair(11, true))  //
);
