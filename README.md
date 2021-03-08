# Wildfly with eclipselink

This image is based on [Jboss/Wildfly](https://hub.docker.com/r/jboss/wildfly) image, and it has the eclipselink and MySQL modules already  install.

### How to use it:
You can run this image using docker run or by docker-compose. With both you can set some useful environment variables:
**Datasource Variable:**

 - DB_HOST 
 - DB_PORT 
 - DB_NAME 
 - DB_USER 
 - DB_PASS

This environment variables allow the wildfly to automatically create a datasource from a mysql database. If you want to change this variables after the first run keep in mind that you should recreate the container in order to recreate the datasource.

**Port forwarding:**

- 8080 - Http port
- 9990 - Admin console port
- 8787 - Debuging port

**Debugging:**
To be able to debug your code you have to enable the debug by set the environment variable DEBUGGING to true, and you also have to forward the port 8787 to the host to be able to attach the debugger to it.

**Code deploy to wildfly:**
To deploy your code to wildfly you have to map `/opt/jboss/wildfly/standalone/deployments/` to some folder from the host.
