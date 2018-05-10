import ATV from 'atvjs';
import API from 'lib/api';
import template from './template.hbs';

var AccountPage = ATV.Page.create({
	name: 'account',
	template: template,
	afterReady: function(doc){
		let email = ATV.Settings.get('email');
		let password = ATV.Settings.get('password');
		let loggedIn = ATV.Settings.get('loggedIn');
	}
});

export default AccountPage;