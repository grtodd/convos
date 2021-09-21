#!perl
use lib '.';
use t::Helper;
use t::Server::Irc;
use Convos::Core;

my $server = t::Server::Irc->new->start;
my $core   = Convos::Core->new;
my ($connection, $host, $user, %connecting, @states);

$core->connect_delay(0.1)->start;

subtest 'create user' => sub {
  $user = $core->user({email => 'jhthorsen@cpan.org', uid => 42});
  $user->save_p->$wait_success('save_p');
};

subtest 'create connection' => sub {
  $connection = $user->connection({url => 'irc://example'});
  $connection->on(state => sub { push @states, $_[2] });
  $connection->save_p->$wait_success('save_p');
};

subtest 'close connection from server side after connect' => sub {
  my $stream;

  @states = ();
  is $core->connect_queue_size, 0, 'nothing in queue';
  $server->once(connection => sub { $stream = $_[2] });
  $server->client($connection)->server_event_ok('_irc_event_nick')->process_ok('connect');
  $host       = $connection->url->host;
  %connecting = (message => "Connecting to $host...", state => 'connecting');
  is_deeply \@states, [\%connecting, {message => "Connected to $host.", state => 'connected'}],
    'states'
    or diag explain \@states;

  @states = ();
  $stream->close;
  Mojo::Promise->timer(0.05)->wait;
  is $core->connect_queue_size, 1, 'one connection is waiting to connect';
  is_deeply \@states,
    [
    {message => 'Connection closed.',         state => 'disconnected'},
    {message => 'Reconnecting after 0.1s...', state => 'queued'}
    ],
    'states'
    or diag explain \@states;
};

subtest 'connection error' => sub {
  my $stream;
  @states = ();
  $server->once(connection => sub { $stream = $_[2] });
  is $core->connect_queue_size, 1, 'one item in queue after close above';
  $core->_dequeue;
  Mojo::Promise->timer(0.1)->wait;
  is $core->connect_queue_size, 0, 'nothing in queue after reconnect';
  is_deeply \@states, [\%connecting, {message => "Connected to $host.", state => 'connected'}],
    'states'
    or diag explain \@states;

  @states = ();
  $connection->{stream}->emit(error => 'Yikes!');
  $stream->close;
  is_deeply \@states,
    [
    {message => 'Yikes!',                     state => 'disconnected'},
    {message => 'Reconnecting after 0.2s...', state => 'queued'}
    ],
    'states'
    or diag explain \@states;
};

done_testing;
