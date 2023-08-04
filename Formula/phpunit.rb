class Phpunit < Formula
  desc "Programmer-oriented testing framework for PHP"
  homepage "https://phpunit.de"
  url "https://phar.phpunit.de/phpunit-10.3.1.phar"
  sha256 "745a668393c135572d9b431d191cd03b8c11c923570e983aeb95b4a59d117779"
  license "BSD-3-Clause"

  livecheck do
    url "https://phar.phpunit.de/phpunit.phar"
    regex(%r{/phpunit[._-]v?(\d+(?:\.\d+)+)\.phar}i)
    strategy :header_match
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "4737ee19c2ddaccd2018650ec90aa92ccbcb5d8162c51c93f4db6015ad5231d0"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "4737ee19c2ddaccd2018650ec90aa92ccbcb5d8162c51c93f4db6015ad5231d0"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "4737ee19c2ddaccd2018650ec90aa92ccbcb5d8162c51c93f4db6015ad5231d0"
    sha256 cellar: :any_skip_relocation, ventura:        "4737ee19c2ddaccd2018650ec90aa92ccbcb5d8162c51c93f4db6015ad5231d0"
    sha256 cellar: :any_skip_relocation, monterey:       "4737ee19c2ddaccd2018650ec90aa92ccbcb5d8162c51c93f4db6015ad5231d0"
    sha256 cellar: :any_skip_relocation, big_sur:        "4737ee19c2ddaccd2018650ec90aa92ccbcb5d8162c51c93f4db6015ad5231d0"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "ec7587308fcacf7813e82dd509a7af31fb2b7c015e7423e6dfe6d0884cd228ad"
  end

  depends_on "php" => :test

  def install
    bin.install "phpunit-#{version}.phar" => "phpunit"
  end

  test do
    (testpath/"src/autoload.php").write <<~EOS
      <?php
      spl_autoload_register(
          function($class) {
              static $classes = null;
              if ($classes === null) {
                  $classes = array(
                      'email' => '/Email.php'
                  );
              }
              $cn = strtolower($class);
              if (isset($classes[$cn])) {
                  require __DIR__ . $classes[$cn];
              }
          },
          true,
          false
      );
    EOS

    (testpath/"src/Email.php").write <<~EOS
      <?php
        declare(strict_types=1);

        final class Email
        {
            private $email;

            private function __construct(string $email)
            {
                $this->ensureIsValidEmail($email);

                $this->email = $email;
            }

            public static function fromString(string $email): self
            {
                return new self($email);
            }

            public function __toString(): string
            {
                return $this->email;
            }

            private function ensureIsValidEmail(string $email): void
            {
                if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                    throw new InvalidArgumentException(
                        sprintf(
                            '"%s" is not a valid email address',
                            $email
                        )
                    );
                }
            }
        }
    EOS

    (testpath/"tests/EmailTest.php").write <<~EOS
      <?php
      declare(strict_types=1);

      use PHPUnit\\Framework\\TestCase;

      final class EmailTest extends TestCase
      {
          public function testCanBeCreatedFromValidEmailAddress(): void
          {
              $this->assertInstanceOf(
                  Email::class,
                  Email::fromString('user@example.com')
              );
          }

          public function testCannotBeCreatedFromInvalidEmailAddress(): void
          {
              $this->expectException(InvalidArgumentException::class);

              Email::fromString('invalid');
          }

          public function testCanBeUsedAsString(): void
          {
              $this->assertEquals(
                  'user@example.com',
                  Email::fromString('user@example.com')
              );
          }
      }

    EOS
    assert_match(/^OK \(3 tests, 3 assertions\)$/,
      shell_output("#{bin}/phpunit --bootstrap src/autoload.php tests/EmailTest.php"))
  end
end
