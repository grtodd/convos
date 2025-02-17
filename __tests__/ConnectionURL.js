import ConnectionURL from '../assets/js/ConnectionURL';

test('ConnectionURL http', () => {
  const url = new ConnectionURL('http://convos.chat/');
  expect(url.toString()).toBe('http://convos.chat/');

  url.href = 'https://convos.chat/';
  expect(url.toString()).toBe('https://convos.chat/');
});

test('ConnectionURL irc', () => {
  const url = new ConnectionURL('irc://irc.example.com/%23convos?nick=supergirl');
  expect(url.toString()).toBe('irc://irc.example.com/%23convos?nick=supergirl');

  url.href = 'irc://irc.example.com:6667/%23convos?nick=superduper';
  expect(url.toString()).toBe('irc://irc.example.com:6667/%23convos?nick=superduper');

  url.searchParams.delete('nick');
  expect(url.toString()).toBe('irc://irc.example.com:6667/%23convos');
  expect(url.host).toBe('irc.example.com:6667');
  expect(url.pathname).toBe('/%23convos');

  url.href = 'irc://x:y@irc.example.com:6667';
  expect(url.username).toBe('x');
  expect(url.password).toBe('y');
});

test('toFields', () => {
  const url = new ConnectionURL('irc://irc.example.com/');

  expect(url.toFields()).toEqual({
    conversation_id: '',
    host: 'irc.example.com',
    local_address: '',
    nick: '',
    password: '',
    protocol: 'irc',
    realname: '',
    sasl: 'none',
    tls: false,
    tls_verify: false,
    username: '',
  });
});

test('fromFields, toFields', () => {
  const url = new ConnectionURL('irc://0:z%5E2JhFX99%25r@convos.chat:6697/%23convos?local_address=1.2.3.4&sasl=cool&nick=Super&realname=Clark&tls=1&tls_verify=0');

  expect(url.toFields()).toEqual({
    conversation_id: '#convos',
    host: 'convos.chat:6697',
    local_address: '1.2.3.4',
    nick: 'Super',
    password: 'z^2JhFX99%r',
    protocol: 'irc',
    realname: 'Clark',
    sasl: 'cool',
    tls: true,
    tls_verify: false,
    username: '0',
  });

  expect(new ConnectionURL().fromFields(url.toFields()).toString())
    .toBe('irc://0:z%5E2JhFX99%25r@convos.chat:6697/%23convos?local_address=1.2.3.4&nick=Super&realname=Clark&sasl=cool&tls=1&tls_verify=0');
});
