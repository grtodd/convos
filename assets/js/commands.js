import {i18n} from '../store/I18N';
import {is} from './util';

export const commands = [];
export const rewriteRule = {};

export function commandOptions({query}) {
  const opts = [];

  for (let i = 0; i < commands.length; i++) {
    if (commands[i].cmd.indexOf(query) != 0) continue;
    const val = commands[i].alias || commands[i].cmd;
    opts.push({val, text: i18n.md(commands[i].example)});
  }

  return opts;
}

export function normalizeCommand(command) {
  const parts = command.split(/\s/);
  const rule = rewriteRule[parts[0].toLowerCase()];
  if (is.function(rule)) return rule(parts.slice(1));
  if (rule) return [rule].concat(parts.slice(1)).filter(p => is.defined(p) && p.length).join(' ');
  return command;
}

const add = (cmd, example, description) => commands.push({cmd, description, example});

// The order is based on the (subjective) frequency of the command
add('/me', '/me <msg>', 'Send message as an action.');
add('/say', '/say <msg>', 'Used when you want to send a message starting with "/".');
add('/whois', '/whois <nick>', 'Show information about a user.');
add('/query', '/query <nick>', 'Open up a new chat window with nick.');
add('/msg', '/msg <nick> <msg>', 'Send a direct message to nick.');
add('/shrug', '/shrug <msg>', 'Add a shrug to end of message. Message is optional.');
add('/join', '/join <#channel>', 'Join channel and open up a chat window.');
add('/close', '/close [nick|#channel]', 'Close conversation.');
add('/nick', '/nick <nick>', 'Change your wanted nick.');
add('/away', '/away <message>', 'Add or remove an away message');
add('/kick', '/kick <nick>', 'Kick a user from the current channel.');
add('/mode', '/mode [+|-][b|o|v] <user>', 'Change mode of yourself or a user');
add('/topic', '/topic or /topic <new topic>', 'Show current topic, or set a new one.');
add('/names', '/names', 'Show participants in the channel.');
add('/invite', '/invite <nick> [#channel]', 'Invite a user to a channel.');
add('/reconnect', '/reconnect', 'Restart the current connection.');
add('/clear', '/clear history <#channel> or /clear history <nick>', 'Delete all history for the given conversation.');
add('/oper', '/oper <nick> <password>', 'Gain operator status on a network.');
add('/cs', '/cs <msg>', 'Send a message to chanserv.');
add('/ns', '/ns <msg>', 'Send a message to nickserv.');
add('/ms', '/ms <msg>', 'Send a message to memoserv.');
add('/hs', '/hs <msg>', 'Send a message to hostserv.');
add('/bs', '/bs <msg>', 'Send a message to botserv.');
add('/os', '/os <msg>', 'Send a message to operserv.');
add('/quote', '/quote <irc-command>', 'Allow you to send any raw IRC message.');

const rewrite = (from, to) => (rewriteRule[from] = to);

rewrite('/close', '/part');
rewrite('/shrug', (parts) => '/say ' + parts.concat('¯\\_(ツ)_/¯').join(' '));
rewrite('/cs', '/quote chanserv');
rewrite('/ns', '/quote nickserv');
rewrite('/ms', '/quote memoserv');
rewrite('/hs', '/quote hotserv');
rewrite('/bs', '/quote botserv');
rewrite('/os', '/quote operserv');
rewrite('/j', '/join');
rewrite('/raw', '/quote');
