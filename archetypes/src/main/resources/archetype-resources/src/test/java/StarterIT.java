package $package;

import com.flowlogix.testcontainers.PayaraServerLifecycleExtension;
import com.flowlogix.util.ShrinkWrapManipulator;
import org.eu.ingwar.tools.arquillian.extension.suite.annotations.ArquillianSuiteDeployment;
import org.jboss.arquillian.container.test.api.Deployment;
import org.jboss.arquillian.junit5.ArquillianExtension;
import org.jboss.shrinkwrap.api.spec.JavaArchive;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(PayaraServerLifecycleExtension.class)
@ExtendWith(ArquillianExtension.class)
@ArquillianSuiteDeployment
class StarterIT {
    @Test
    void sanityCheck() {
        assertThat(true).isTrue();
    }

    @Deployment
    static JavaArchive deploy() {
        return ShrinkWrapManipulator.createDeployment(JavaArchive.class);
    }
}
