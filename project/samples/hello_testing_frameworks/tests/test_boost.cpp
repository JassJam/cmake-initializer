#include <boost/test/included/unit_test.hpp>
#include "math_utils.hpp"

BOOST_AUTO_TEST_SUITE(MathUtilsTestSuite)

BOOST_AUTO_TEST_CASE(TestAddition)
{
    BOOST_CHECK_EQUAL(math_utils::Add(2, 3), 5);
    BOOST_CHECK_EQUAL(math_utils::Add(-1, 1), 0);
    BOOST_CHECK_EQUAL(math_utils::Add(-5, -3), -8);
    BOOST_CHECK_EQUAL(math_utils::Add(0, 0), 0);
}

BOOST_AUTO_TEST_CASE(TestSubtraction)
{
    BOOST_CHECK_EQUAL(math_utils::Subtract(5, 3), 2);
    BOOST_CHECK_EQUAL(math_utils::Subtract(1, 1), 0);
    BOOST_CHECK_EQUAL(math_utils::Subtract(-5, -3), -2);
    BOOST_CHECK_EQUAL(math_utils::Subtract(0, 5), -5);
}

BOOST_AUTO_TEST_CASE(TestMultiplication)
{
    BOOST_CHECK_EQUAL(math_utils::Multiply(3, 4), 12);
    BOOST_CHECK_EQUAL(math_utils::Multiply(-2, 3), -6);
    BOOST_CHECK_EQUAL(math_utils::Multiply(-2, -3), 6);
    BOOST_CHECK_EQUAL(math_utils::Multiply(0, 100), 0);
}

BOOST_AUTO_TEST_CASE(TestDivision)
{
    BOOST_CHECK_EQUAL(math_utils::Divide(10, 2), 5);
    BOOST_CHECK_EQUAL(math_utils::Divide(-10, 2), -5);
    BOOST_CHECK_EQUAL(math_utils::Divide(-10, -2), 5);
    BOOST_CHECK_EQUAL(math_utils::Divide(7, 3), 2);

    BOOST_CHECK_THROW(math_utils::Divide(5, 0), std::invalid_argument);
}

BOOST_AUTO_TEST_CASE(TestPrimeChecking)
{
    // Test small primes
    BOOST_CHECK(!math_utils::IsPrime(2));
    BOOST_CHECK(math_utils::IsPrime(3));
    BOOST_CHECK(math_utils::IsPrime(5));
    BOOST_CHECK(math_utils::IsPrime(7));
    BOOST_CHECK(math_utils::IsPrime(11));
    BOOST_CHECK(math_utils::IsPrime(13));

    // Test non-primes
    BOOST_CHECK(!math_utils::IsPrime(1));
    BOOST_CHECK(!math_utils::IsPrime(4));
    BOOST_CHECK(!math_utils::IsPrime(6));
    BOOST_CHECK(!math_utils::IsPrime(8));
    BOOST_CHECK(!math_utils::IsPrime(9));
    BOOST_CHECK(!math_utils::IsPrime(10));

    // Test negative numbers and zero
    BOOST_CHECK(!math_utils::IsPrime(0));
    BOOST_CHECK(!math_utils::IsPrime(-1));
    BOOST_CHECK(!math_utils::IsPrime(-5));
}

BOOST_AUTO_TEST_CASE(TestFactorial)
{
    BOOST_CHECK_EQUAL(math_utils::Factorial(0), 1);
    BOOST_CHECK_EQUAL(math_utils::Factorial(1), 1);
    BOOST_CHECK_EQUAL(math_utils::Factorial(2), 2);
    BOOST_CHECK_EQUAL(math_utils::Factorial(3), 6);
    BOOST_CHECK_EQUAL(math_utils::Factorial(4), 24);
    BOOST_CHECK_EQUAL(math_utils::Factorial(5), 120);

    BOOST_CHECK_THROW(math_utils::Factorial(-1), std::invalid_argument);
    BOOST_CHECK_THROW(math_utils::Factorial(-5), std::invalid_argument);
}

BOOST_AUTO_TEST_SUITE_END()
