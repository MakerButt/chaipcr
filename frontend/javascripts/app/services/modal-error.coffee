App.service 'ModalError', [
  '$uibModal'
  '$rootScope'
  ($uibModal, $rootScope) ->

    self = @
    $scope = $rootScope.$new()

    self.open = (err) ->
      $scope.title = err.title || 'ERROR'
      $scope.message = err.message
      $scope.date = err.date

      $uibModal.open
        templateUrl: 'app/views/directives/error-modal.html'
        scope: $scope
        windowClass: 'modal-error-window'

    return self

]