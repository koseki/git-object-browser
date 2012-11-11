
angular.module('GitServices', ['ngResource'])
  .factory('GitResource', function($resource) {
    var GitResource = $resource('/.git/:path');
    return GitResource;
  })
  .factory('PackedRefsResource', function($resource) {
    var resource = $resource('/.git/packed-refs');
    return resource;
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
      whenPath('/.git', 10, {controller:GitCtrl, templateUrl:'templates/git.html'}).
      otherwise({redirectTo:'/.git/'});
  })

  .directive('entryIcon', function($parse) {
    return function(scope, element, attrs) {
      var icons = {
        'directory': 'icon-folder-open',
        'ref': 'icon-map-marker',
        'packed_refs': 'icon-map-marker',
        'index': 'icon-list',
        'file': 'icon-file',
        'object': 'icon-comment',
        'blob': 'icon-file',
        'tree': 'icon-folder-open',
        'commit': 'icon-ok',
        'tag': 'icon-tag'
      };

      var entryType = ($parse(attrs.entryIcon))(scope);
      element.addClass(icons[entryType]);
    }
  })

  .directive('modeIcon', function($parse) {
    return function(scope, element, attrs) {
      var mode = ($parse(attrs.modeIcon))(scope);
      var iconClass;
      if (120000 <= mode) {
        iconClass = 'icon-share-alt';
      } else if (100000 <= mode) {
        iconClass = 'icon-file';
      } else {
        iconClass = 'icon-folder-open';
      }
      element.addClass(iconClass);
    }
  })

  .directive('refHref', function($parse) {
    return function(scope, element, attrs) {
      var entry = ($parse(attrs.refHref))(scope);
      var href = "";
      var sha1 = null;

      if (typeof(entry) == 'string') {
        sha1 = entry;
      } else if (entry && entry.sha1) {
        sha1 = entry.sha1;
      }

      if (sha1 !== null) {
        href = '#/.git/objects/' + sha1.substr(0, 2) + '/' + sha1.substr(2);
      } else if (entry && entry.ref) {
        href = '#/.git/' + entry.ref;
      }

      element.attr('href', href);
    }
  })

  .filter('unixtime', function($filter) {
    return function(input, format) {
      return ($filter('date'))(input * 1000, format);
    }
  });

function GitCtrl($scope, $location, $routeParams, GitResource) {
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

  $scope.findIndexEntry = function(sha1) {
    var entries = $scope.object.entries;
    var entry = null;
    angular.forEach(entries, function(value) {
      if (value.sha1 == sha1) {
        entry = value;
        return;
      }
    });
    return entry;
  };

  $scope.indexEntryKeys = function(version) {
    var keys = [
      'ctime',
      'cnano',
      'mtime',
      'mnano',
      'dev',
      'ino',
      'object_type',
      'unix_permission',
      'uid',
      'gid',
      'size',
      'sha1',
      'path'
    ]

    if (version == 2) {
      keys = keys.concat([
        'assume_valid_flag',
        'extended_flag',
        'stage',
      ]);
    } else {
      keys = keys.concat([
        'skip_worktree',
        'intent_to_add',
      ]);
    }
    keys.push('name_length');

    return keys;
  };

  $scope.resourceLoaded = function(json) {
    $scope.workingdir = json.workingdir;
    $scope.root = json.root;
    if (json.path == "") {
      $scope.path = ".git";
    } else {
      $scope.path = ".git/" + json.path;
    }
    $scope.object = json.object;
    $scope.keys = $scope.indexEntryKeys($scope.object.version);
    var template;
    if (json.path == "objects") {
      template = "objects";
      $scope.objectTable = $scope.objectTable($scope.object.entries);
    } else if (json.type == "index" && $routeParams.sha1) {
      template = "index_entry";
      $scope.entry = $scope.findIndexEntry($routeParams.sha1);
    } else if (json.type == "packed_refs" && $routeParams.ref) {
      template = json.type;
      var entries = [];
      angular.forEach($scope.object.entries, function(entry) {
        if (entry.ref == $routeParams.ref) {
          entries.push(entry);
          $scope.limited = true;
        }
      });
      $scope.object.entries = entries;
    } else if (json.type == "pack_index") {
      template = json.type;
      angular.forEach($scope.object.fanout, function(fanout, i) {
        if ($scope.object.entries[fanout]) {
          var entry = $scope.object.entries[fanout];
          if (! entry.fanoutMin) {
            entry.fanoutMin = i + 1;
          } else {
            entry.fanoutMax = i + 1;
          }
        } else {
          $scope.object.entries[fanout] = { fanoutMin: i + 1 }
        }
      });
    } else {
      template = json.type;
    }

    $scope.template = 'templates/' + template + '.html';
  };

  $scope.resourceError = function(path) {
    return function(response) {
      if (response.status == 404) {
        $scope.resourceNotFound(path);
      } else {
        $scope.template = 'templates/error.html';
      }
    };
  };

  $scope.resourceNotFound = function(path) {
    $scope.path = path;
    if (path.indexOf('refs/') == 0) {
      $location.url('/.git/packed-refs?ref=' + path);
    } else {
      $scope.template = 'templates/notfound.html';
    }
  };

  GitResource.get({'path': path}, $scope.resourceLoaded, $scope.resourceError(path));

}
