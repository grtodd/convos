#!perl
use lib '.';
use t::Helper;
use Convos::Core;
use Convos::Core::Backend::File;
use List::Util qw(sum);
use Time::HiRes qw(time);

my $core = Convos::Core->new(backend => 'Convos::Core::Backend::File');
my $user;

subtest 'jhthorsen connections' => sub {
  $user = $core->user({email => 'jhthorsen@cpan.org', uid => 42});
  $user->save_p->$wait_success('save_p');

  # 1: oragono.local connects instantly
  $core->connection_profile({url => 'irc://oragono.local'})->skip_queue(true)
    ->save_p->$wait_success('save_p');
  $user->connection({url => 'irc://oragono.local'})->save_p->$wait_success('save_p');

  # 2: instant or queued
  $user->connection({connection_id => 'irc-magnet'})
    ->tap(sub { shift->url->parse('irc://irc.perl.org') })->save_p->$wait_success('save_p');
  $user->connection({connection_id => 'irc-magnet2'})
    ->tap(sub { shift->url->parse('irc://irc.perl.org') })->save_p->$wait_success('save_p');
};

subtest 'mramberg connections' => sub {
  $user = $core->user({email => 'mramberg@cpan.org', uid => 32});
  $user->save_p->$wait_success('save_p');

  # 0: will not be connected
  my $conn_0 = $user->connection({url => 'irc://oragono.local'});
  $conn_0->wanted_state('disconnected')->url->parse('irc://127.0.0.1');
  $conn_0->save_p->$wait_success('save_p');

  # 2: instant or queued
  $user->connection({url => 'irc://libera'})
    ->tap(sub { shift->url->parse('irc://irc.libera.chat:6697') })->save_p;
  $user->connection({url => 'irc://magnet'})->tap(sub { shift->url->parse('irc://irc.perl.org') })
    ->save_p;
};

subtest 'restart core' => sub {
  my ($ready_p, %connect) = (Mojo::Promise->new);
  $core = Convos::Core->new(backend => 'Convos::Core::Backend::File')->connect_delay(0.1);
  $core->once(ready => sub { $ready_p->resolve });

  Mojo::Util::monkey_patch(
    'Convos::Core::Connection::Irc',
    connect_p => sub {
      my $host_port = $_[0]->url->host_port;
      note "$host_port=" . (++$connect{$host_port});
      $ready_p->resolve if sum(values %connect) >= 5;
      return Mojo::Promise->resolve({});
    }
  );

  $core->start for 0 .. 4;    # calling start() multiple times does not do anything
  $ready_p->wait;
  cmp_deeply $core->{connect_queue},
    {
    'irc.libera.chat' => [],
    'irc.perl.org'    => [map { [ignore, (obj_isa('Convos::Core::Connection::Irc'))] } 1 .. 2]
    },
    'connect_queue';
  is_deeply \%connect, {'irc.libera.chat:6697' => 1, 'irc.perl.org' => 1, 'oragono.local' => 1},
    'skip queue for some connections and skipped wanted_state=disconnected';

  $ready_p = Mojo::Promise->new;
  Mojo::Promise->race($ready_p, Mojo::Promise->timer(2))->wait;
  is_deeply \%connect, {'irc.libera.chat:6697' => 1, 'irc.perl.org' => 3, 'oragono.local' => 1},
    'started duplicate connection delayed';

  is $core->get_user('mramberg@cpan.org')->uid, 32, 'uid from storage';
};

done_testing;
