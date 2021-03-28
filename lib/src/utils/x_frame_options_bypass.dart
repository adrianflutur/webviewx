import 'package:webviewx/src/utils/css_loader.dart';

import 'constants.dart';

class XFrameOptionsBypass {
  static String build({
    CssLoader cssloader = const CssLoader(),
    bool printDebugInfo = false,
  }) =>
      '''
if (customElements.get('x-frame-bypass') == undefined) {
  defineCustomElementsBuiltIn();
  defineXFrameBypass();
}

function defineCustomElementsBuiltIn() {
  !function(P,H,k){"use strict";if(1==P.importNode.length&&!H.get("ungap-li")){var D="extends";try{var e={extends:"li"},t=HTMLLIElement,n=function(){return Reflect.construct(t,[],n)};if(n.prototype=k.create(t.prototype),H.define("ungap-li",n,e),!/is="ungap-li"/.test((new n).outerHTML))throw e}catch(e){!function(){var s="attributeChangedCallback",n="connectedCallback",r="disconnectedCallback",e=Element.prototype,l=k.assign,t=k.create,o=k.defineProperties,a=k.getOwnPropertyDescriptor,u=k.setPrototypeOf,c=H.define,i=H.get,f=H.upgrade,v=H.whenDefined,p=t(null),d=new WeakMap,g={childList:!0,subtree:!0};Reflect.ownKeys(self).filter(function(e){return"string"==typeof e&&/^HTML(?!Element)/.test(e)}).forEach(function(e){function t(){}var n=self[e];u(t,n),(t.prototype=n.prototype).constructor=t,(n={})[e]={value:t},o(self,n)}),new MutationObserver(m).observe(P,g),O(Document.prototype,"importNode"),O(Node.prototype,"cloneNode"),o(H,{define:{value:function(e,t,n){if(e=e.toLowerCase(),n&&D in n){p[e]=l({},n,{Class:t});for(var r=n[D]+'[is="'+e+'"]',o=P.querySelectorAll(r),a=0,i=o.length;a<i;a++)A(o[a])}else c.apply(H,arguments)}},get:{value:function(e){return e in p?p[e].Class:i.call(H,e)}},upgrade:{value:function(e){var t=L(e);!t||e instanceof t.Class?f.call(H,e):N(e,t)}},whenDefined:{value:function(e){return e in p?Promise.resolve():v.call(H,e)}}});var h=P.createElement;o(P,{createElement:{value:function(e,t){var n=h.call(P,e);return t&&"is"in t&&(n.setAttribute("is",t.is),H.upgrade(n)),n}}});var b=a(e,"attachShadow").value,y=a(e,"innerHTML");function m(e){for(var t=0,n=e.length;t<n;t++){for(var r=e[t],o=r.addedNodes,a=r.removedNodes,i=0,l=o.length;i<l;i++)A(o[i]);for(i=0,l=a.length;i<l;i++)C(a[i])}}function w(e){for(var t=0,n=e.length;t<n;t++){var r=e[t],o=r.attributeName,a=r.oldValue,i=r.target,l=i.getAttribute(o);s in i&&(a!=l||null!=l)&&i[s](o,a,i.getAttribute(o),null)}}function C(e){var t;1===e.nodeType&&((t=L(e))&&e instanceof t.Class&&r in e&&d.get(e)!==r&&(d.set(e,r),Promise.resolve(e).then(T)),E(e,C))}function L(e){var t=e.getAttribute("is");return t&&(t=t.toLowerCase())in p?p[t]:null}function M(e){e[n]()}function T(e){e[r]()}function N(e,t){var n=t.Class,r=n.observedAttributes||[];if(u(e,n.prototype),r.length){new MutationObserver(w).observe(e,{attributes:!0,attributeFilter:r,attributeOldValue:!0});for(var o=[],a=0,i=r.length;a<i;a++)o.push({attributeName:r[a],oldValue:null,target:e});w(o)}}function A(e){var t;1===e.nodeType&&((t=L(e))&&(e instanceof t.Class||N(e,t),n in e&&e.isConnected&&d.get(e)!==n&&(d.set(e,n),Promise.resolve(e).then(M))),E(e,A))}function E(e,t){for(var n=e.content,r=(n&&11==n.nodeType?n:e).querySelectorAll("[is]"),o=0,a=r.length;o<a;o++)t(r[o])}function O(e,t){var n=e[t],r={};r[t]={value:function(){var e=n.apply(this,arguments);switch(e.nodeType){case 1:case 11:E(e,A)}return e}},o(e,r)}o(e,{attachShadow:{value:function(){var e=b.apply(this,arguments);return new MutationObserver(m).observe(e,g),e}},innerHTML:{get:y.get,set:function(e){y.set.call(this,e),/\bis=("|')?[a-z0-9_-]+\1/i.test(e)&&E(this,A)}}})}()}}}(document,customElements,Object);
}

function defineXFrameBypass() {
customElements.define('x-frame-bypass', class extends HTMLIFrameElement {
	static get observedAttributes() {
		return ['src']
	}
	constructor () {
		super()
	}
	attributeChangedCallback () {
		this.load(this.src)
	}

	load(url, options) {
    if (!options) {
      
      console.log('${printDebugInfo ? 'Options was null. Now set to empty object' : ''}')
      options = {}
    }

    if (url == 'about:blank') {
      this.srcdoc = '<br>'
      return
    }

    try {
      var matches = url.match(/(.*)(\\[$BYPASS_URL_ADDITIONAL_OPTIONS_STARTING_POINT\\])(.*)/)
      var uri = matches[1]
      var headers = JSON.parse(atob(matches[3]))

      // If we made it here, then the navigation was made from controller
      console.log('${printDebugInfo ? 'Navigated from controller' : ''}')

      url = uri
      
      if (headers) {
        options.headers = headers
      }
    } catch (err) {
      // NOOP
      console.log('${printDebugInfo ? 'Navigated from click' : ''}')
    }
    console.log(${printDebugInfo ? 'options' : ''})

    this.srcdoc = `${cssloader.build()}`
  
		this.fetchProxy(url, options, 0).then(res => res.text()).then(data => {
			if (data) {
				var source = data.replace(/<head([^>]*)>/i, `<head\$1>
	        <base href="\${url}">
	        <script>
	        document.addEventListener('click', e => {
	        	if (frameElement && document.activeElement && document.activeElement.href) {
	        		e.preventDefault()
              frameElement.contentWindow.$WEB_HISTORY_CALLBACK && frameElement.contentWindow.$WEB_HISTORY_CALLBACK(document.activeElement.href)

	        		frameElement.load(document.activeElement.href)
	        	}
	        })
	        document.addEventListener('submit', e => {
	        	if (frameElement && document.activeElement && document.activeElement.form && document.activeElement.form.action) {
	        		e.preventDefault()

	        		if (document.activeElement.form.method === 'post') {
                frameElement.contentWindow.$WEB_HISTORY_CALLBACK && frameElement.contentWindow.$WEB_HISTORY_CALLBACK(document.activeElement.form.action)

	        			frameElement.load(document.activeElement.form.action, {method: 'post', body: new FormData(document.activeElement.form)})
              } else {
                var urlWithQueryParams = document.activeElement.form.action + '?' + new URLSearchParams(new FormData(document.activeElement.form))
                frameElement.contentWindow.$WEB_HISTORY_CALLBACK && frameElement.contentWindow.$WEB_HISTORY_CALLBACK(urlWithQueryParams)

	        			frameElement.load(urlWithQueryParams)
              }
	        	}
	        })
	        </script>`)

        this.srcdoc = source
      }

    //TODO should be possible to send this error to a dart callback, which will then be sent to the OnWebResourceError callback
		}).catch(e => console.error('Cannot fetch URL content:', e))
	}

  //TODO should be possible to add my own proxy list without this js null-checking mess
	fetchProxy (url, options, i) {
		const proxies = (options || {}).proxies || [
      'https://cors.bridged.cc/',
			'https://api.codetabs.com/v1/proxy/?quest='
		]
		return fetch(proxies[i] + url, options).then(res => {
			if (!res.ok)
				throw new Error(`\${res.status} \${res.statusText}`);

			return res
		}).catch(error => {
			if (i === proxies.length - 1)
				throw error
			return this.fetchProxy(url, options, i + 1)
		})
	}
}, {extends: 'iframe'})
}
''';
}
