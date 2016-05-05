import docker
import docker.utils

def client():
    args = docker.utils.kwargs_from_env(assert_hostname = False)
    args['version'] = '1.12'
    return docker.Client(**args)
