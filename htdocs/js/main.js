
angular.module('GitServices', ['ngResource'])
  .factory('GitResource', function($resource) {
    var GitResource = $resource('/.git/:path');
    return GitResource;
  });

angular.module('GitObjectBrowser', ['GitServices'])
  .config(function($routeProvider) {
    $routeProvider = angular.extend($routeProvider, {

      // AngularJS doesn't support regular expressions in routes.
      // http://stackoverflow.com/questions/12685085/angularjs-route-how-to-match-star-as-a-path
      'whenPath': function(path, depth, route) {
        for (var i = 1; i <= depth; i++) {
          path += '/:path' + i;
          this.when(path, route);
        }
        return this;
      }
    });

    $routeProvider.
      when('/', {controller:HomeCtrl, templateUrl:'templates/home.html'}).
      whenPath('/.git', 10, {controller:GitCtrl, templateUrl:'templates/git.html'}).
      otherwise({redirectTo:'/'});
  })

  .directive('entryIcon', function($parse) {
    return function(scope, element, attrs) {
      var icons = {
        'directory': 'icon-folder-open',
        'ref': 'icon-map-marker',
        'index': 'icon-list',
        'file': 'icon-file',
        'object': 'icon-comment'
      };

      var entryType = ($parse(attrs.entryIcon))(scope);
      element.addClass(icons[entryType]);
    }
  })

  .directive('refHref', function($parse) {
    return function(scope, element, attrs) {
      var entry = ($parse(attrs.refHref))(scope);
      var href = "";
      if (entry.sha1) {
        href = '#/.git/objects/' + entry.sha1.substr(0, 2) + '/' + entry.sha1.substr(2);
      } else if (entry.ref) {
        href = '#/.git/' + entry.ref;
      }

      element.attr('href', href);
    }
  })

  .directive('objectProp', function($parse) {
    return function(scope, element, attrs) {
      var prop = ($parse(attrs.objectProp))(scope);
      var match = prop[1].match(/^([0-9a-f]{2})([0-9a-f]{38})$/)
      if (match) {
        match[0] + '/' + match[1]
      }
    }
  });


function HomeCtrl($scope) {
}

function GitCtrl($scope, $routeParams, GitResource) {
  $scope.template = 'templates/loading.html';
  var path = '';
  for (var i = 1; i <= 10; i++) {
    if ($routeParams['path' + i]) {
      if (i > 1) path += '/';
      path += $routeParams['path' + i];
    }
  }

  $scope.objectTable = function(entries) {
    var rows = [];
    var hash = {};

    angular.forEach(entries, function(entry) {
      hash[entry.basename] = entry;
    })

    var hex = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'];
    for (var i = 0; i < 16; i++) {
      var cols = [];
      for (var j = 0; j < 16; j++) {
        if (hash[hex[i] + hex[j]]) {
          cols[j] = hash[hex[i] + hex[j]];
        } else {
          cols[j] = {'basename': hex[i] + hex[j], 'type': 'empty'};
        }
      }
      rows[i] = cols;
    }
    return rows;
  }

  GitResource.get({'path': path}, function(object) {
    $scope.workingdir = object.workingdir;
    $scope.root = object.root;
    if (object.path == "") {
      $scope.path = ".git";
    } else {
      $scope.path = ".git/" + object.path;
    }
    $scope.object = object.object;

    var template;
    if (object.path == "objects") {
      template = "objects";
      $scope.objectTable = $scope.objectTable($scope.object.entries);
    } else {
      template = object.type;
    }

    $scope.template = 'templates/' + template + '.html';
  });
  
}
