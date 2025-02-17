#!perl
use lib '.';
use t::Helper;
use Mojo::File 'curfile';
use Mojo::JSON 'encode_json';

$ENV{CONVOS_BACKEND} = 'Convos::Core::Backend';
$ENV{MOJO_MODE}      = 'production';
$ENV{NODE_ENV}       = 'production';

SKIP: {
  skip 'BUILD_ASSETS=1 to run "npm run build"', 1 unless $ENV{BUILD_ASSETS} or $ENV{RELEASE};
  build_assets();
}

my $t = t::Helper->t;

subtest 'path /' => sub {
  test_defaults('/' => 200);

  $t->get_ok('/')->status_is(200)->content_like(qr[href="/asset/convos\.[0-9a-f]{8}\.css"])
    ->content_like(qr[src="/asset/convos\.[0-9a-f]{8}\.js"]);
};

subtest 'path /err/404' => sub {
  test_defaults('/err/404' => 404)->element_exists('a.btn[href="/"]')
    ->text_is('title', 'Not Found (404) - Convos')->text_is('h1', 'Not Found (404)');
};

subtest 'path /err/500' => sub {
  test_defaults('/err/500' => 500)
    ->element_exists('a[href="https://github.com/convos-chat/convos/issues/"]')
    ->element_exists('a.btn[href="/"]')->text_is('title', 'Internal Server Error (500) - Convos')
    ->text_is('h1', 'Internal Server Error (500)');
};

done_testing;

sub build_assets {
  opendir(my $ASSETS, 'public/asset');
  /^convos\.[0-9a-f]{8}\.(css|js)\b/ and unlink "public/asset/$_" while $_ = readdir $ASSETS;
  diag qq(\nPlease consult https://convos.chat/doc/develop for details about "npm".\n\n)
    unless is system('npm run build'), 0, 'run "npm run build"';
}

sub test_defaults {
  my ($path, $status) = @_;
  $t->get_ok($path)->status_is($status)->content_like(qr[href="/asset/convos\.[0-9a-f]{8}\.css"]);
  $t->content_like(qr[src="/asset/convos\.[0-9a-f]{8}\.js"]) unless $status == 500;
  return $t;
}
