
angular.module('GitObjectBrowser', ['ngResource'])
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

  .directive('scrollBottom', function() {
    return function(scope, elm, attr) {
      var rawDomElement = elm[0];
      angular.element(window).unbind('scroll');
      angular.element(window).bind('scroll', function() {
        if (! scope.scrollBottomEnabled) return;

        var rectObject = rawDomElement.getBoundingClientRect();
        if (rectObject.bottom - window.innerHeight < 50) {
          scope.$apply(attr.scrollBottom);
        }
      });
    };
  })

  .directive('entryIcon', function($parse) {
    return function(scope, element, attrs) {
      var icons = {
        'directory': 'icon-folder-open',
        'ref': 'icon-map-marker',
        'info_refs': 'icon-map-marker',
        'packed_refs': 'icon-map-marker',
        'index': 'icon-list',
        'file': 'icon-file',
        'object': 'icon-comment',
        'blob': 'icon-file',
        'tree': 'icon-folder-open',
        'commit': 'icon-ok',
        'tag': 'icon-tag',
        'ofs_delta': 'icon-arrow-up',
        'ref_delta': 'icon-arrow-down'
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

function GitCtrl($scope, $location, $routeParams, $resource) {
  // reset scrollBottom event handler
  angular.element(window).unbind('scroll');

  var objectTable = function(entries) {
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

  var findIndexEntry = function(sha1) {
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

  var indexEntryKeys = function(version) {
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
      'assume_valid_flag',
      'extended_flag',
      'stage',
      'name_length'
    ]
    if (version > 2) {
      keys = keys.concat([
        'skip_worktree',
        'intent_to_add',
      ]);
    }
    keys.push('path')

    return keys;
  };

  var resourceLoaded = function(json) {
    $scope.workingdir = json.workingdir;
    $scope.root = json.root;
    $scope.gitPath = json.path;
    if (json.path == "") {
      $scope.path = ".git";
    } else {
      $scope.path = ".git/" + json.path;
    }
    $scope.object = json.object;
    $scope.keys = indexEntryKeys($scope.object.version);
    var template;
    if (json.path == "objects") {
      template = "objects";
      $scope.objectTable = objectTable($scope.object.entries);
    } else if (json.type == "index" && $routeParams.sha1) {
      template = "index_entry";
      $scope.entry = findIndexEntry($routeParams.sha1);
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
    } else if (json.type == "packed_object") {
      template = json.type;
      $scope.unpacked = json.unpacked;
    } else {
      template = json.type;
    }

    $scope.template = 'templates/' + template + '.html';
  };

  $scope.resourceError = function(path) {
    return function(response) {
      if (response.status == 404) {
        resourceNotFound(path);
      } else {
        $scope.status = response.status;
        $scope.path = path;
        $scope.template = 'templates/error.html';
      }
    };
  };

  var resourceNotFound = function(path) {
    $scope.path = path;
    if (path.indexOf('refs/') == 0) {
      $location.url('/.git/packed-refs?ref=' + path);
    } else {
      $scope.template = 'templates/notfound.html';
    }
  };

  var buildPath = function() {
    var path = '';
    for (var i = 1; i <= 10; i++) {
      if ($routeParams['path' + i]) {
        if (i > 1) path += '/';
        path += $routeParams['path' + i];
      }
    }
    return path;
  }

  var loadJson = function(path) {
    $scope.template = 'templates/loading.html';

    if (path.match(/^objects\/pack\/pack-[0-9a-f]{40}\.pack$/) && $routeParams.offset) {
      var offset = '0000' + $routeParams.offset;
      path = 'json/' + path.replace(/:/, '\\:')
        + '/' + offset.slice(-2)
        + '/' + offset.slice(-4, -2)
        + '/' + $routeParams.offset + '.json';
    } else if (path.match(/^objects\/pack\/pack-[0-9a-f]{40}\.idx$/)) {
      var order = $routeParams.order == 'offset' ? 'offset' : 'sha1';
      var page  = $routeParams.page || 1;
      path = 'json/' + path.replace(/:/, '\\:') + '/' + order + '/' + page + '.json';
    } else {
      if (path == '') path = '_git';
      path = 'json/' + path.replace(/:/, '\\:') + '.json';
    }
    $resource(path).get({}, resourceLoaded, $scope.resourceError(path));
  };

  loadJson(buildPath());
}

function PackFileCtrl($scope, $location, $routeParams) {
  $scope.indexUrl = $scope.path.replace(/.pack$/, '.idx');
}

function PackIndexCtrl($scope, $location, $routeParams, $resource) {

  $scope.packUrl = $scope.path.replace(/.idx$/, '.pack');
  $scope.firstPage = 1;
  $scope.lastPage = 1;
  $scope.scrollBottomEnabled = true;

  var resourceLoaded = function(json) {
    $scope.object.entries = $scope.object.entries.concat(json.object.entries);
    $scope.scrollBottomEnabled = ! json.object.last_page;
    $scope.loading = false;
  }

  $scope.loadNextPage = function() {
    $scope.lastPage += 1;

    var order = $routeParams.order == 'offset' ? 'offset' : 'sha1';
    var path = 'json/' + $scope.gitPath.replace(/:/, '\\:') + '/' + order + '/' + $scope.lastPage + '.json';

    $resource(path).get({}, resourceLoaded, $scope.resourceError(path));
  };

  $scope.scrollBottom = function() {
    $scope.scrollBottomEnabled = false;
    $scope.loading = true;
    $scope.loadNextPage();
  }

}
