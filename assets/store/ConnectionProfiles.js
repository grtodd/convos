import ConnectionURL from '../js/ConnectionURL';
import Reactive from '../js/Reactive';
import {api} from '../js/Api';

export default class ConnectionProfiles extends Reactive {
  constructor(params) {
    super(params);
    this.prop('ro', 'op', api('/api', 'listConnectionProfiles'));
    this.prop('rw', 'profiles', []);
    this.prop('rw', 'status', 'pending');
  }

  find(id) {
    return this.search(p => p.id == id)[0];
  }

  defaultProfile() {
    return {max_bulk_message_size: 3, max_message_length: 512, url: new ConnectionURL('irc://0.0.0.0')};
  }

  is(status) {
    return this.status == status;
  }

  async load(params = {}) {
    if (this.is('loading')) return this;
    if (!params.force && this.profiles.length) return this;
    this.update({status: 'loading'});
    await this.op.perform();
    this.update({status: this.op.status});
    if (this.is('success')) this.update({profiles: this.op.res.body.profiles.map(p => this._expand(p))});
    return this;
  }

  search(filter = () => true) {
    return this.profiles.filter(filter);
  }

  _expand(profile) {
    profile.url = new ConnectionURL(profile.url);
    profile.service_accounts = profile.service_accounts.join(', ');
    profile.url.toFields(profile);

    const def = this.defaultProfile();
    Object.keys(def).forEach(k => profile.hasOwnProperty(k) || (profile[k] = def[k]));

    return profile;
  }
}
